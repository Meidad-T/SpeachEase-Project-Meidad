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
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let isActive = isDateActive(date)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isActive ? Color.green : Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        // Empty placeholder for start of month alignment
                         RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clear)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: monthDate) else { return [] }
        
        let numDays = range.count
        let firstWeekday = calendar.component(.weekday, from: monthDate)
        
        // Add nil for offset (weekday - 1 because Sunday is 1)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...numDays {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        return days
    }
    
    private func isDateActive(_ date: Date) -> Bool {
        // Simple day matching
        for activeDate in activeDates {
            if calendar.isDate(activeDate, inSameDayAs: date) {
                return true
            }
        }
        return false
    }
}
