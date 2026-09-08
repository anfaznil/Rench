import Foundation

/// Builds `tel:`/`sms:` URLs for the phone-call and text actions.
enum ContactActions {
    private static func sanitizedPhoneURL(scheme: String, phone: String) -> URL? {
        let allowed = phone.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "\(scheme):\(allowed)")
    }

    static func callURL(phone: String) -> URL? {
        sanitizedPhoneURL(scheme: "tel", phone: phone)
    }

    static func textURL(phone: String, body: String? = nil) -> URL? {
        guard let base = sanitizedPhoneURL(scheme: "sms", phone: phone) else { return nil }
        guard let body, !body.isEmpty else { return base }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "body", value: body)]
        return components?.url ?? base
    }
}
