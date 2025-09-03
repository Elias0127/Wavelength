import SwiftUI

// MARK: - Entry Detail View
struct EntryDetailView: View {
    let entry: Entry
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var viewModel: EntryDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(entry: Entry, appViewModel: AppViewModel) {
        self.entry = entry
        self.appViewModel = appViewModel
        self._viewModel = StateObject(wrappedValue: EntryDetailViewModel(
            entry: entry,
            onUpdate: { updatedEntry in
                appViewModel.updateEntry(id: updatedEntry.id) { entry in
                    entry = updatedEntry
                }
            },
            onDelete: { id in
                appViewModel.deleteEntry(id: id)
            }
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text(viewModel.entry.title)
                                .h1()
                                .multilineTextAlignment(.leading)
                            
                            Text(viewModel.entry.formattedDate)
                                .captionText()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.sm) {
                            Button(action: {
                                viewModel.toggleFavorite()
                            }) {
                                Image(systemName: viewModel.entry.favorite ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.entry.favorite ? DesignTokens.Colors.danger : DesignTokens.Colors.textSecondary)
                                    .font(.system(size: 20))
                            }
                            
                            ModeBadge(mode: viewModel.entry.mode)
                        }
                    }
                    
                    // Tags
                    if !viewModel.entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ForEach(viewModel.entry.tags, id: \.self) { tag in
                                    TagChip(text: tag)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
                .cardBackground()
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // Transcript section
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Your Words")
                        .h2()
                    
                    Text(viewModel.entry.transcript)
                        .bodyText()
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                }
                .cardBackground()
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // Counselor reply section
                if viewModel.hasCounselorReply {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        HStack {
                            Text("Reflection")
                                .h2()
                            
                            Spacer()
                            
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                        
                        Text(viewModel.entry.counselorReply ?? "")
                            .bodyText()
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                // Valence chart section
                if viewModel.hasValenceData {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Mood Pattern")
                            .h2()
                        
                        VStack(spacing: DesignTokens.Spacing.md) {
                            // Chart
                            MiniLineChart(data: viewModel.entry.valenceSeries)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(DesignTokens.Colors.card)
                                )
                            
                            // Description
                            HStack {
                                Text("Average: \(viewModel.valenceDescription)")
                                    .captionText()
                                
                                Spacer()
                                
                                Text(viewModel.entry.feeling.displayName)
                                    .pill(
                                        backgroundColor: Color(hex: viewModel.entry.feeling.color),
                                        textColor: .white
                                    )
                            }
                        }
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                // Action buttons
                VStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        viewModel.confirmDelete()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Entry")
                        }
                        .secondaryButton()
                    }
                    .foregroundColor(DesignTokens.Colors.danger)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.surface)
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .alert("Delete Entry", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteEntry()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EntryDetailView(
            entry: MockEntries.seed[0],
            appViewModel: AppViewModel()
        )
    }
}
