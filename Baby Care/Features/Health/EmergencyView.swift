import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct EmergencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PediatricContact.createdAt) private var contacts: [PediatricContact]

    @State private var showAddContact = false
    @State private var editingContact: PediatricContact?

    var body: some View {
        List {
            Section {
                Text("Acil durumda doğru numaraya ulaşmak için zaman kaybetmeyin. Tek dokunuşla aramak için aşağıdaki numaralara basın.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    FirstAidView()
                } label: {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("İlk Yardım Rehberi")
                                .font(.subheadline.weight(.semibold))
                            Text("Boğulma, CPR, ateş, yanık, düşme…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Ulusal Acil Hatlar") {
                emergencyRow(
                    icon: "phone.badge.checkmark.fill",
                    color: .red,
                    title: "112 — Acil Yardım",
                    subtitle: "Ambulans, hayati tehlike",
                    number: "112"
                )
                emergencyRow(
                    icon: "cross.case.fill",
                    color: .blue,
                    title: "184 — SABİM",
                    subtitle: "Sağlık Bakanlığı İletişim",
                    number: "184"
                )
                emergencyRow(
                    icon: "drop.triangle.fill",
                    color: .green,
                    title: "114 — UZEM",
                    subtitle: "Ulusal Zehir Danışma Merkezi",
                    number: "114"
                )
                emergencyRow(
                    icon: "shield.lefthalf.filled",
                    color: .indigo,
                    title: "155 — Polis İmdat",
                    subtitle: "Güvenlik",
                    number: "155"
                )
            }

            Section {
                if contacts.isEmpty {
                    Text("Henüz kayıtlı pediatristiniz yok. Bilgilerini ekleyin, acil anda hızlıca arayın.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(contacts) { contact in
                        contactRow(contact)
                    }
                }
                Button {
                    editingContact = nil
                    showAddContact = true
                } label: {
                    Label("Pediatrist / Doktor Ekle", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Bebeğinizin Doktoru")
            }

            #if os(iOS)
            Section("Hastane Bulucu") {
                Button {
                    openMapsForHospitals()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("En Yakın Çocuk Hastanesini Bul")
                                .font(.subheadline.weight(.medium))
                            Text("Apple Maps'te aç")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            #endif

            Section {
                Text("Hayati tehlike şüphesi varsa zaman kaybetmeden **112**'yi arayın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Acil")
        .inlineNavigationTitle()
        .sheet(isPresented: $showAddContact) {
            PediatricContactEditSheet(contact: nil)
        }
        .sheet(item: $editingContact) { contact in
            PediatricContactEditSheet(contact: contact)
        }
    }

    private func emergencyRow(icon: String, color: Color, title: String, subtitle: String, number: String) -> some View {
        Button {
            call(number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "phone.fill")
                    .foregroundStyle(color)
                    .font(.subheadline)
            }
        }
        .buttonStyle(.plain)
    }

    private func contactRow(_ contact: PediatricContact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.pink)
                    .frame(width: 24)
                Text(contact.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    editingContact = contact
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let phone = contact.phone, !phone.isEmpty {
                Button {
                    call(phone)
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.green)
                        Text(phone)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.green.opacity(0.1), in: .capsule)
                }
                .buttonStyle(.plain)
            }

            if let address = contact.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = contact.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func call(_ number: String) {
        #if os(iOS)
        let cleaned = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    #if os(iOS)
    private func openMapsForHospitals() {
        let query = "çocuk hastanesi"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
    #endif
}

// MARK: - Edit sheet

struct PediatricContactEditSheet: View {
    let contact: PediatricContact?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool { contact != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ad / Klinik") {
                    TextField("Örn: Dr. Ayşe Yılmaz / Acıbadem Çocuk", text: $name)
                }
                Section("Telefon") {
                    TextField("+90 532 123 45 67", text: $phone)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                }
                Section("Adres (isteğe bağlı)") {
                    TextField("Klinik veya muayene adresi", text: $address, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Not (isteğe bağlı)") {
                    TextField("Muayene saatleri, sigorta, vs.", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Düzenle" : "Yeni Pediatrist")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let c = contact else { return }
        name = c.name
        phone = c.phone ?? ""
        address = c.address ?? ""
        notes = c.notes ?? ""
    }

    private func save() {
        let cleanedPhone = phone.trimmingCharacters(in: .whitespaces)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = contact {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.phone = cleanedPhone.isEmpty ? nil : cleanedPhone
            existing.address = cleanedAddress.isEmpty ? nil : cleanedAddress
            existing.notes = cleanedNotes.isEmpty ? nil : cleanedNotes
            existing.updatedAt = .now
        } else {
            let new = PediatricContact(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: cleanedPhone.isEmpty ? nil : cleanedPhone,
                address: cleanedAddress.isEmpty ? nil : cleanedAddress,
                notes: cleanedNotes.isEmpty ? nil : cleanedNotes
            )
            modelContext.insert(new)
        }

        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let c = contact else { return }
        modelContext.delete(c)
        try? modelContext.save()
        dismiss()
    }
}
