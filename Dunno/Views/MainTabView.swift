import SwiftUI

private enum MainTab: CaseIterable, Identifiable {
    case tasks, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .tasks: "Tasks"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .tasks: "checklist"
        case .settings: "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selection: MainTab = .tasks

    var body: some View {
        // The bar is stacked below the content (not overlaid), so each screen's
        // own bottom controls always sit above it.
        VStack(spacing: 0) {
            Group {
                switch selection {
                case .tasks: TaskListView()
                case .settings: SettingsView()
                }
            }
            .frame(maxHeight: .infinity)

            DunnoTabBar(selection: $selection)
        }
        .background(Color.dunnoBase.ignoresSafeArea())
    }
}

/// Dunno's floating tab bar: the selected tab is an accent pill with its label,
/// the others show only their icon. The pill slides between tabs.
private struct DunnoTabBar: View {
    @Binding var selection: MainTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases) { tab in
                let isSelected = selection == tab
                Button {
                    withAnimation(.snappy(duration: 0.3)) { selection = tab }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                        if isSelected {
                            Text(tab.title)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .fixedSize()
                        }
                    }
                    .foregroundStyle(isSelected ? Color.dunnoOnAccent : Color.secondary)
                    .padding(.horizontal, isSelected ? 20 : 18)
                    .frame(height: 48)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.dunnoAccent)
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Color.dunnoSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.06)))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        .padding(.bottom, 6)
    }
}
