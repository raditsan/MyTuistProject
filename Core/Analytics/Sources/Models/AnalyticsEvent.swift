import Foundation

public struct AnalyticsEvent: @unchecked Sendable {
    public let name: String
    public let parameters: [String: Any]?

    public init(name: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - Standard Events Helper
extension AnalyticsEvent {
    public static func screenView(screenName: String, screenClass: String? = nil) -> AnalyticsEvent {
        var params: [String: Any] = ["screen_name": screenName]
        if let screenClass = screenClass {
            params["screen_class"] = screenClass
        }
        return AnalyticsEvent(name: "screen_view", parameters: params)
    }

    public static func buttonClick(buttonName: String, screenName: String? = nil) -> AnalyticsEvent {
        var params: [String: Any] = ["button_name": buttonName]
        if let screenName = screenName {
            params["screen_name"] = screenName
        }
        return AnalyticsEvent(name: "button_click", parameters: params)
    }
}

// MARK: - E-Commerce Standard Taxonomy (GA4 / Firebase Standard)
extension AnalyticsEvent {
    public static func viewItem(
        id: String,
        name: String,
        price: Double,
        category: String? = nil,
        currency: String = "IDR"
    ) -> AnalyticsEvent {
        var params: [String: Any] = [
            "item_id": id,
            "item_name": name,
            "price": price,
            "currency": currency
        ]
        if let category = category {
            params["item_category"] = category
        }
        return AnalyticsEvent(name: "view_item", parameters: params)
    }

    public static func viewItemList(category: String, itemsCount: Int) -> AnalyticsEvent {
        return AnalyticsEvent(name: "view_item_list", parameters: [
            "item_category": category,
            "items_count": itemsCount
        ])
    }

    public static func addToCart(
        id: String,
        name: String,
        price: Double,
        quantity: Int = 1,
        currency: String = "IDR"
    ) -> AnalyticsEvent {
        return AnalyticsEvent(name: "add_to_cart", parameters: [
            "item_id": id,
            "item_name": name,
            "price": price,
            "quantity": quantity,
            "currency": currency
        ])
    }

    public static func removeFromCart(
        id: String,
        name: String,
        price: Double,
        quantity: Int = 1,
        currency: String = "IDR"
    ) -> AnalyticsEvent {
        return AnalyticsEvent(name: "remove_from_cart", parameters: [
            "item_id": id,
            "item_name": name,
            "price": price,
            "quantity": quantity,
            "currency": currency
        ])
    }

    public static func beginCheckout(value: Double, itemsCount: Int, currency: String = "IDR") -> AnalyticsEvent {
        return AnalyticsEvent(name: "begin_checkout", parameters: [
            "value": value,
            "items_count": itemsCount,
            "currency": currency
        ])
    }

    public static func purchase(
        orderId: String,
        value: Double,
        itemsCount: Int,
        currency: String = "IDR"
    ) -> AnalyticsEvent {
        return AnalyticsEvent(name: "purchase", parameters: [
            "transaction_id": orderId,
            "value": value,
            "items_count": itemsCount,
            "currency": currency
        ])
    }

    public static func search(query: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "search", parameters: [
            "search_term": query
        ])
    }
}
