import SwiftUI
struct TestView: View {
    @State private var pos: String?
    var body: some View {
        ScrollView {
            Text("Test")
        }
        .scrollPosition(id: $pos, anchor: .top)
    }
}
