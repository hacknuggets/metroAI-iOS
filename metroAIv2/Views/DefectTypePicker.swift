import SwiftUI

struct DefectTypePicker: View {
    @Binding var selectedDefect: Defect?
    let categories: [String: DefectCategory]

    var body: some View {
        List {
            ForEach(sortedCategories, id: \.key) { categoryKey, category in
                Section(header: Text(category.name)) {
                    ForEach(category.defects) { defect in
                        Button {
                            selectedDefect = defect
                        } label: {
                            HStack {
                                Text(defect.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedDefect?.id == defect.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var sortedCategories: [(key: String, value: DefectCategory)] {
        categories.sorted { $0.value.name < $1.value.name }
    }
}

#Preview {
    DefectTypePicker(
        selectedDefect: .constant(nil),
        categories: [
            "seats": DefectCategory(
                name: "Сиденья",
                defects: [
                    Defect(id: "1", name: "Порванное сиденье"),
                    Defect(id: "2", name: "Грязное сиденье")
                ]
            )
        ]
    )
}
