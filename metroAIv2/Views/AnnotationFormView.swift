import SwiftUI
import SwiftData
import CoreLocation

struct AnnotationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var viewModel: CameraViewModel

    @State private var showDefectPicker = false
    @State private var showStationPicker = false

    var body: some View {
        NavigationStack {
            Form {
                if let image = viewModel.capturedImage {
                    Section {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Section {
                    Button {
                        showDefectPicker = true
                    } label: {
                        HStack {
                            Text("Тип дефекта")
                                .foregroundColor(.primary)
                            Spacer()
                            if let defect = viewModel.selectedDefect {
                                Text(defect.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Выберите")
                                    .foregroundColor(.red)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Дефект *")
                }

                Section {
                    Button {
                        showStationPicker = true
                    } label: {
                        HStack {
                            Text("Станция")
                                .foregroundColor(.primary)
                            Spacer()
                            if let station = viewModel.selectedStation {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(station.name)
                                        .foregroundColor(.secondary)
                                    Text(station.lineName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(viewModel.isFetchingLocation ? "Определение..." : "Не выбрано")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Местоположение")
                } footer: {
                    if !viewModel.nearbyStations.isEmpty {
                        Text("Найдено \(viewModel.nearbyStations.count) станций рядом")
                    }
                }

                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Примечания")
                } footer: {
                    Text("Опишите дефект подробнее (необязательно)")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Описание дефекта")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.reset()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.submit(modelContext: modelContext)
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Сохранить")
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                }
            }
            .sheet(isPresented: $showDefectPicker) {
                NavigationStack {
                    DefectTypePicker(
                        selectedDefect: $viewModel.selectedDefect,
                        categories: viewModel.defectCategories
                    )
                    .navigationTitle("Тип дефекта")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .onChange(of: viewModel.selectedDefect) { _, newValue in
                    if newValue != nil {
                        showDefectPicker = false
                    }
                }
            }
            .sheet(isPresented: $showStationPicker) {
                NavigationStack {
                    StationPickerView(
                        selectedStation: $viewModel.selectedStation,
                        nearbyStations: viewModel.nearbyStations,
                        allStations: viewModel.allStations,
                        currentLocation: nil
                    )
                    .navigationTitle("Выбор станции")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .onChange(of: viewModel.selectedStation) { _, newValue in
                    if newValue != nil {
                        showStationPicker = false
                    }
                }
            }
        }
    }
}
