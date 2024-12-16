import SwiftUI

struct LoginView: View {
    @ObservedObject var fetcher: InfoDataFetcher

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginStatus: String = ""
    var ipv4 = ""
    var ipv6 = ""

    @FocusState private var isUsernameFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isUsernameFieldFocused)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isUsernameFieldFocused)

            Button(action:  {
                Task {
                    try await login()
                }
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if !loginStatus.isEmpty {
                Text(loginStatus)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func login() async throws {
        let LoginData = try await fetchLoginData(urlString: "https://login.ku.ac.th/")
        // Prepare the URL and request
        guard let url = URL(string: LoginData.urlLogin+"/index.jsp?action=login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")


        // Construct POST body (url-encoded parameters)
        let parameters = [
            "username": username,
            "password": password,
            "ipv4": LoginData.ipv4,
            "ipv6": LoginData.ipv6,
            "loginType": "specific",
            "loginMethod": "ldap",
            "submit": "Log In",
            "hashc": LoginData.hashc,
            "mac": "",
            "hash": ""
        ]

        let bodyString = parameters
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")

        let bodyData = bodyString.data(using: .utf8)

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        print("Request URL: \(request.url?.absoluteString ?? "No URL")")
        print("Request Method: \(request.httpMethod ?? "No HTTP Method")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "No Body")")

        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { loginStatus = "Invalid server response." }
                return
            }

            print(httpResponse.statusCode)

            if httpResponse.statusCode == 200 {
                // Assume login success if HTTP status is 200
                DispatchQueue.main.async {
                    loginStatus = "Login successful!"
                    fetcher.fetchData()
                }
            } else {
                DispatchQueue.main.async {
                    loginStatus = "Login failed. Please check your credentials."
                }
            }
        }.resume()
    }
}
