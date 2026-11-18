import SwiftUI

struct ContentView: View {
    @StateObject private var repository = GymRepository.shared

    var body: some View {
        HomeView(repository: repository)
    }
}
