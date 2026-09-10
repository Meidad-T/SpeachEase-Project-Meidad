import SwiftUI

struct YearlyHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let activityDates: Set<Date>
    
    // Calendar Logic
    private let calendar = Calendar.current
    private let year = Calendar.current.component(.year, from: Date())
    private let months = 1...12
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Stats
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(activityDates.count)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Active Days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
