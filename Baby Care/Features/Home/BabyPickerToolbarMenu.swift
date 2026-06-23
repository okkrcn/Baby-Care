import SwiftUI

/// Birden fazla bebek varsa NavigationStack toolbar'ında bebek seçici menü gösterir.
/// Tek bebek varsa sadece ismi gösterir.
struct BabyPickerToolbarMenu: View {
    @Environment(SelectedBabyStore.self) private var store
    let babies: [Baby]
    let selected: Baby?

    var body: some View {
        if babies.count > 1 {
            Menu {
                ForEach(babies) { baby in
                    Button {
                        store.select(baby)
                    } label: {
                        if baby.id == selected?.id {
                            Label(baby.name, systemImage: "checkmark")
                        } else {
                            Text(baby.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selected?.name ?? "Bebek")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
        } else {
            Text(selected?.name ?? "Bebek")
                .font(.headline)
        }
    }
}
