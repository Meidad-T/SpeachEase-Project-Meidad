import SwiftUI

import SwiftUI

import SwiftUI

struct AnalysisResultView: View {
    let report: SpeechReport
    var isLoading: Bool = false 
    var onOpenTranscript: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
