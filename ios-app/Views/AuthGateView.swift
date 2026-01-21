import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        if authVM.isAuthenticated {
            RootTabView()
        } else {
            LoginView()
        }
    }
}
