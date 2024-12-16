import SwiftSoup
import WebKit

enum NetworkError: Error {
    case invalidURL
    case requestFailed(String)
}


func fetchInfoData() async throws ->  InfoData {
    let urlString = "https://info.ku.ac.th"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        throw NetworkError.invalidURL
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let html = String(data: data, encoding: .utf8) else {
        print("Failed to get data or decode HTML")
        throw NetworkError.requestFailed("Failed to get data or decode HTML")
    }

    do {
        // Parse the HTML using SwiftSoup
        let document = try SwiftSoup.parse(html)

        let remainingSelector = "body > div.container-fluid > div > div.col-sm-5.col-md-4 > div > div > div > div:nth-child(2) > table > tbody > tr > td:nth-child(2) > div > span"

        // Extract the desired values
        let maxQuota = try Double(document.select("small:contains(Max Quota)").text().replacingOccurrences(of: "Max Quota ", with: "").replacingOccurrences(of: " GB", with: "")) ?? 0
        let remaining = try Double(document.select(remainingSelector).text().replacingOccurrences(of: " GB", with: "")) ?? 0
        let user = try document.select("small:contains(user:)").text().replacingOccurrences(of: "user: ", with: "")
        let ipv4 = try document.select("small:contains(IPv4:)").text().replacingOccurrences(of: "IPv4: ", with: "")
        let ipv6 = try document.select("small:contains(IPv6:)").text().replacingOccurrences(of: "IPv6: ", with: "")
        let status = try document.select("span.badge").text()

        // Print the extracted values
        print("Max Quota: \(maxQuota)")
        print("Remaining: \(remaining)")
        print("User: \(user)")
        print("IPv4: \(ipv4)")
        print("IPv6: \(ipv6)")
        print("Status: \(status)")

        // Return the extracted values
        return InfoData(maxQuota: maxQuota, remaining: remaining, user: user, ipv4: ipv4, ipv6: ipv6, status: status)
    } catch {
        throw NetworkError.requestFailed("Failed to parse HTML")
    }
}

struct LoginData {
    let ipv4: String
    let ipv6: String
    let hashc: String
    let urlLogin: String
}

func fetchLoginData(urlString:String) async throws -> LoginData {
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        throw NetworkError.invalidURL
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let html: String = String(data: data, encoding: .utf8) else {
        print("Failed to get data or decode HTML")
        throw NetworkError.requestFailed("Failed to get data or decode HTML")
    }
    if let newURL = extractRedirectURL(from: html) {
            print("Redirecting to: \(newURL)")
            // Recursive call to perform login to the new URL
            return try await fetchLoginData(urlString: newURL)
        }
    var hashc: String = "non"
    do {
        // Parse the HTML using SwiftSoup
        let document = try SwiftSoup.parse(html)
        print(try document.select("#hashc"))
        hashc = try document.select("#hashc").attr("value")
    } catch {
        throw NetworkError.requestFailed("Failed to parse HTML")
    }

    let ipv4Url = "https://v4-login3.ku.ac.th/engines/ipv4"
    let ipv6Url = "https://v6-login1.ku.ac.th/engines/ipv6"

    let ipv4Request = URLRequest(url: URL(string: ipv4Url)!)
    let ipv6Request = URLRequest(url: URL(string: ipv6Url)!)

    let ipv4Data = try await URLSession.shared.data(for: ipv4Request)
    let ipv6Data = try await URLSession.shared.data(for: ipv6Request)

    let ipv4 = String(data: ipv4Data.0, encoding: .utf8) ?? "N/A"
    let ipv6 = String(data: ipv6Data.0, encoding: .utf8) ?? "N/A"

    return LoginData(ipv4: ipv4, ipv6: ipv6, hashc: hashc, urlLogin: urlString)
}

func extractRedirectURL(from response: String) -> String? {
    // Use a regular expression to find the URL in 'window.location'
    let pattern: String = #"window\.location\s*=\s*"([^"]+)"#
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
        if let match = regex.firstMatch(in: response, options: [], range: nsRange),
           let range = Range(match.range(at: 1), in: response) {
            return String(response[range])
        }
    }
    return nil
}