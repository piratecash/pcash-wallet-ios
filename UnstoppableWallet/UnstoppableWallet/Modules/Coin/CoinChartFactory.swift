import Chart
import Foundation
import MarketKit
import UIKit

class CoinChartFactory {
    private let dateFormatter = DateFormatter()

    init(currentLocale: Locale) {
        dateFormatter.locale = currentLocale
    }

    func convert(item: CoinChartService.Item, periodType: HsPeriodType, currency: Currency) -> ChartModule.ViewItem {
        var points = item.chartPointsItem.points
        var firstPoint = item.chartPointsItem.firstPoint
        var lastPoint = item.chartPointsItem.lastPoint

        // add current rate point, if last point older
        if item.timestamp > lastPoint.timestamp {
            let point = ChartPoint(timestamp: item.timestamp, value: item.rate)

            points.append(point)
            lastPoint = point

            var pointToPrepend: ChartPoint?

            if periodType.in([.hour24]), let rateDiff24 = item.rateDiff24h {
                // for 24h chart we need change oldest visible point to 24h back timestamp-same point
                let timestamp = item.timestamp - 24 * 60 * 60
                let value = 100 * item.rate / (100 + rateDiff24)

                pointToPrepend = ChartPoint(timestamp: timestamp, value: value)
            } else if periodType.in([.day1]), let rateDiff1d = item.rateDiff1d {
                // for 1day chart we need change oldest visible point to 24h back timestamp-same point
                let value = 100 * item.rate / (100 + rateDiff1d)

                pointToPrepend = ChartPoint(timestamp: TimeInterval.midnightUTC(), value: value)
            }

            if let pointToPrepend {
                if let index = points.firstIndex(where: { $0.timestamp > pointToPrepend.timestamp }) {
                    points.insert(pointToPrepend, at: index)
                    if index > 0 {
                        points.remove(at: index - 1)
                    }
                }

                firstPoint = pointToPrepend
            }
        }

        let items = points.map { point in
            let item = ChartItem(timestamp: point.timestamp).added(name: ChartData.rate, value: point.value)

            if let volume = point.volume {
                item.added(name: ChartData.volume, value: volume)
            }

            return item
        }

        let chartData = ChartData(items: items, startWindow: firstPoint.timestamp, endWindow: lastPoint.timestamp)
        let diff = (lastPoint.value - firstPoint.value) / firstPoint.value * 100
        let diffString = ValueFormatter.instance.format(percentValue: diff, signType: .always)
        let valueDiff = diffString.map { ValueDiff(value: $0, trend: diff.isSignMinus ? .down : .up) }
        return ChartModule.ViewItem(
            value: ValueFormatter.instance.formatFull(currencyValue: CurrencyValue(currency: currency, value: item.rate)),
            valueDescription: nil,
            rightSideMode: .none,
            chartData: chartData,
            indicators: item.indicators,
            chartTrend: lastPoint.value > firstPoint.value ? .up : .down,
            chartDiff: valueDiff,
            limitFormatter: { value in ValueFormatter.instance.formatFull(currency: currency, value: value) }
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, indicators: [ChartIndicator], firstChartItem _: ChartItem?, currency: Currency) -> ChartModule.SelectedPointViewItem? {
        guard let rate = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.formatFull(currency: currency, value: rate)

        let volumeString: String? = chartItem.indicators[ChartData.volume].flatMap {
            if $0.isZero {
                return nil
            }
            return ValueFormatter.instance.formatShort(currency: currency, value: $0).map {
                "chart.selected.volume".localized + " " + $0
            }
        }

        let visibleMaIndicators = indicators
            .filter {
                $0.onChart && $0.enabled
            }
            .compactMap {
                $0 as? MaIndicator
            }

        let visibleBottomIndicators = indicators
            .filter {
                !$0.onChart && $0.enabled
            }

        let rightSideMode: ChartModule.RightSideMode
        // If no any visible indicators, we show only volume
        if visibleMaIndicators.isEmpty, visibleBottomIndicators.isEmpty {
            rightSideMode = .volume(value: volumeString)
        } else {
            let maPairs = visibleMaIndicators.compactMap { ma -> (Decimal, UIColor)? in
                // get value if ma-indicator and it's color
                guard let value = chartItem.indicators[ma.json] else {
                    return nil
                }
                let color = ma.configuration.color.value.withAlphaComponent(1)
                return (value, color)
            }
            // build top-line string
            let topLineString = NSMutableAttributedString()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.right

            for (index, pair) in maPairs.enumerated() {
                let formatted = ValueFormatter.instance.formatFull(value: pair.0, decimalCount: 8, signType: pair.0 < 0 ? .always : .never)
                topLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: pair.1.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
                if index < maPairs.count - 1 {
                    topLineString.append(NSAttributedString(string: " "))
                }
            }
            // build bottom-line string
            let bottomLineString = NSMutableAttributedString()
            switch visibleBottomIndicators.first {
            case let rsi as RsiIndicator:
                let value = chartItem.indicators[rsi.json]
                let formatted = value.flatMap {
                    ValueFormatter.instance.formatFull(value: $0, decimalCount: 2, signType: $0 < 0 ? .always : .never)
                }
                bottomLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: rsi.configuration.color.value.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
            case let macd as MacdIndicator:
                var pairs = [(Decimal, UIColor)]()
                // histogram pair
                let histogramName = MacdIndicator.MacdType.histogram.name(id: macd.json)
                if let histogramValue = chartItem.indicators[histogramName] {
                    let color = histogramValue >= 0 ? macd.configuration.positiveColor : macd.configuration.negativeColor
                    pairs.append((histogramValue, color.value))
                }
                let signalName = MacdIndicator.MacdType.signal.name(id: macd.json)
                if let signalValue = chartItem.indicators[signalName] {
                    pairs.append((signalValue, macd.configuration.fastColor.value))
                }
                let macdName = MacdIndicator.MacdType.macd.name(id: macd.json)
                if let macdValue = chartItem.indicators[macdName] {
                    pairs.append((macdValue, macd.configuration.longColor.value))
                }
                for (index, pair) in pairs.enumerated() {
                    let formatted = ValueFormatter.instance.formatFull(value: pair.0, decimalCount: 8, signType: pair.0 < 0 ? .always : .never)
                    bottomLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: pair.1.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
                    if index < pairs.count - 1 {
                        bottomLineString.append(NSAttributedString(string: " "))
                    }
                }
            default:
                if let volume = volumeString {
                    bottomLineString.append(NSAttributedString(string: volume, attributes: [.foregroundColor: UIColor.themeGray, .paragraphStyle: paragraphStyle]))
                }
            }

            rightSideMode = .indicators(top: topLineString, bottom: bottomLineString)
        }

        return ChartModule.SelectedPointViewItem(
            value: formattedValue,
            date: formattedDate,
            rightSideMode: rightSideMode
        )
    }
}

public extension HsPeriodType {
    func `in`(_ intervals: [HsTimePeriod]) -> Bool {
        switch self {
        case let .byPeriod(interval): return intervals.contains(interval)
        case let .byCustomPoints(interval, _): return intervals.contains(interval)
        case .byStartTime: return false
        }
    }
}
