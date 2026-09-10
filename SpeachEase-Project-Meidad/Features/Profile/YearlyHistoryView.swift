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
                        }
                        
                        VStack {
                            Text("\(year)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Year")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Monthly Grids
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 30) {
                        ForEach(months, id: \.self) { month in
                            MonthGrid(month: month, year: year, activeDates: activityDates)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Yearly Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct MonthGrid: View {
    let month: Int
    let year: Int
    let activeDates: Set<Date>
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Calendar.current.monthSymbols[month - 1])
                .font(.headline)
                .foregroundStyle(.white)
            
