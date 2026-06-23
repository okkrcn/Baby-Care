import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Hoş Geldiniz")
            .inlineNavigationTitle()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: OnboardingViewModel) -> some View {
        @Bindable var vm = viewModel

        Form {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 56))
                        .foregroundStyle(.pink.gradient)
                    Text("Bebeğinizi tanıyalım")
                        .font(.title3.bold())
                    Text("Bilgiler cihazınızda kalır.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("Bebeğin Adı") {
                TextField("Örn: Ada", text: $vm.babyName)
            }

            Section("Doğum") {
                DatePicker(
                    "Tarih",
                    selection: $vm.birthDate,
                    displayedComponents: .date
                )

                Toggle("Saat eklenecek", isOn: $vm.hasBirthTime)

                if vm.hasBirthTime {
                    DatePicker(
                        "Saat",
                        selection: $vm.birthTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Picker("Cinsiyet", selection: $vm.sex) {
                    ForEach(BabySex.allCases, id: \.self) { s in
                        Text(s.localizedTitle).tag(s)
                    }
                }
            }

            Section("Ölçümler (isteğe bağlı)") {
                HStack {
                    Text("Doğum Kilosu (g)")
                    Spacer()
                    TextField("3200", value: $vm.birthWeightGrams, format: .number)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                HStack {
                    Text("Doğum Boyu (cm)")
                    Spacer()
                    TextField("50", value: $vm.birthLengthCm, format: .number)
                        .decimalKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    vm.saveBaby()
                } label: {
                    HStack {
                        if vm.isWorking { ProgressView() }
                        Text("Devam Et").bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!vm.canSaveBaby)
            }
        }
        .formStyle(.grouped)
    }
}
