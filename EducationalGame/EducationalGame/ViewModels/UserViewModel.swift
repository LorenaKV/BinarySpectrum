/// centralized state manager for user-related data
/// provides global access to user progress and achievements

import Observation
import SwiftUI

// MARK: - Global Shared Instance

// Create shared instance for global access
let sharedUserViewModel = UserViewModel()

// Centralized state manager for user-related data that provides global access to user progress and achievements
@Observable class UserViewModel: ObservableObject {
    // MARK: - Published Properties

    var userName: String = ""
    var userAge: String = ""
    var favoriteColor: Color = .gamePurple
    var completedMiniGames: [String: Bool] = [:]
    var miniGameScores: [String: Int] = [:]
    var miniGamePercentages: [String: Double] = [:]
    var achievements: [String] = []
    
    // Experience level properties
    var gameExperienceLevels: [String: ExperienceLevel] = [:]
    var autoAdjustExperienceLevel: Bool = true
    var gamePerformancePercentages: [String: Double] = [:]
    
    // MARK: - Private Constants
    
    // Storage keys for UserDefaults
    private enum StorageKey {
        static let userName = "userName"
        static let userAge = "userAge"
        static let favoriteColor = "favoriteColor"
        static let completedGames = "completedGames"
        static let miniGameScores = "miniGameScores"
        static let miniGamePercentages = "miniGamePercentages"
        static let achievements = "achievements"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        
        // Experience level storage keys
        static let gameExperienceLevels = "gameExperienceLevels"
        static let autoAdjustExperienceLevel = "autoAdjustExperienceLevel"
        static let gamePerformancePercentages = "gamePerformancePercentages"
        
        // Keys that might be used by other parts of the app
        static let gamePhases = [
            "BinaryGamePhase",
            "PixelGamePhase",
            "ColorGamePhase",
            "currentGamePhases"
        ]
    }
    
    // MARK: - Init
    
    init() {
        loadSavedData()
    }
    
    // MARK: - Public Methods
    
    // Check if this is the first launch of the app
    func isFirstLaunch() -> Bool {
        !UserDefaults.standard.bool(forKey: StorageKey.hasLaunchedBefore)
    }
    
    // Set first launch as completed
    func setFirstLaunchCompleted() {
        UserDefaults.standard.set(true, forKey: StorageKey.hasLaunchedBefore)
    }
    
    // Save user information
    func saveUserInfo(name: String, age: String, favoriteColor: Color = .gamePurple) {
        userName = name
        userAge = age
        self.favoriteColor = favoriteColor
        saveData()
    }
    
    // Record completion of a mini game
    func completeMiniGame(_ gameName: String, score: Int, percentage: Double) {
        completedMiniGames[gameName] = true
        miniGameScores[gameName] = score
        miniGamePercentages[gameName] = percentage
        
        // Add achievement if this is the first time completing the game
        if !achievements.contains("Completed \(gameName)") {
            achievements.append("Completed \(gameName)")
        }
        
        // Update experience level based on performance if auto-adjust is enabled
        updateGamePerformance(for: gameName, percentage: percentage)
        
        saveData()
    }
    
    // Check if a mini game has been completed
    func isGameCompleted(_ gameName: String) -> Bool {
        completedMiniGames[gameName] ?? false
    }
    
    // Get the score for a mini game
    func getScore(for gameName: String) -> Int {
        miniGameScores[gameName] ?? 0
    }
    
    // Get the percentage for a mini game
    func getPercentage(for gameName: String) -> Double {
        miniGamePercentages[gameName] ?? 0.0
    }
    
    // Get the experience level for a specific game
    func getExperienceLevel(for gameName: String) -> ExperienceLevel {
        return gameExperienceLevels[gameName] ?? .rookie
    }
    
    // Set the experience level for a specific game
    func setExperienceLevel(_ level: ExperienceLevel, for gameName: String) {
        gameExperienceLevels[gameName] = level
        saveData()
    }
    
    // Set auto-adjust experience level setting
    func setAutoAdjustExperienceLevel(_ enabled: Bool) {
        autoAdjustExperienceLevel = enabled
        saveData()
    }
    
    // Update game performance and adjust experience level if needed
    func updateGamePerformance(for gameName: String, percentage: Double) {
        gamePerformancePercentages[gameName] = percentage
        
        // Only auto-adjust if enabled
        if autoAdjustExperienceLevel {
            // If player gets 75% or more correct, set to pro level
            if percentage >= 0.75 {
                gameExperienceLevels[gameName] = .pro
            } else {
                gameExperienceLevels[gameName] = .rookie
            }
        }
        
        saveData()
    }
    
    // Reset all progress data
    func resetProgress() {
        // Clear all game progress data
        completedMiniGames = [:]
        miniGameScores = [:]
        miniGamePercentages = [:]
        achievements = []
        
        // Reset experience levels to rookie
        for key in gameExperienceLevels.keys {
            gameExperienceLevels[key] = .rookie
        }
        gamePerformancePercentages = [:]
        
        // Save changes to UserDefaults immediately to ensure achievements are reset
        saveData()
        
        // Clear any other game state data that might be stored in UserDefaults
        resetAllGameStates()
        
        // Force refresh any game view models that might be in memory
        NotificationCenter.default.post(name: .resetGameProgress, object: nil)
    }
    
    // MARK: - Private Methods
    
    // Save all user data to UserDefaults
    private func saveData() {
        let defaults = UserDefaults.standard
        
        // Save user information
        defaults.set(userName, forKey: StorageKey.userName)
        defaults.set(userAge, forKey: StorageKey.userAge)
        defaults.set(favoriteColor.storageString, forKey: StorageKey.favoriteColor)
        
        // Save completed games using Swift's Codable protocol
        if let encoded = try? JSONEncoder().encode(completedMiniGames) {
            defaults.set(encoded, forKey: StorageKey.completedGames)
        }
        
        if let encoded = try? JSONEncoder().encode(miniGameScores) {
            defaults.set(encoded, forKey: StorageKey.miniGameScores)
        }
        
        if let encoded = try? JSONEncoder().encode(miniGamePercentages) {
            defaults.set(encoded, forKey: StorageKey.miniGamePercentages)
        }
        
        // Handle achievements
        if achievements.isEmpty {
            // If achievements are empty, explicitly remove from UserDefaults
            defaults.removeObject(forKey: StorageKey.achievements)
        } else if let encoded = try? JSONEncoder().encode(achievements) {
            defaults.set(encoded, forKey: StorageKey.achievements)
        }
        
        // Save experience level settings
        if let encoded = try? JSONEncoder().encode(gameExperienceLevels) {
            defaults.set(encoded, forKey: StorageKey.gameExperienceLevels)
        }
        
        defaults.set(autoAdjustExperienceLevel, forKey: StorageKey.autoAdjustExperienceLevel)
        
        if let encoded = try? JSONEncoder().encode(gamePerformancePercentages) {
            defaults.set(encoded, forKey: StorageKey.gamePerformancePercentages)
        }
        
        // Notify listeners that user data has been updated
        NotificationCenter.default.post(name: .userDataUpdated, object: nil)
    }
    
    // Load all user data from UserDefaults
    private func loadSavedData() {
        let defaults = UserDefaults.standard
        
        // Load user information
        userName = defaults.string(forKey: StorageKey.userName) ?? ""
        userAge = defaults.string(forKey: StorageKey.userAge) ?? ""
        favoriteColor = Color(fromStorage: defaults.string(forKey: StorageKey.favoriteColor) ?? "gamePurple")
        
        // Load saved game data using Swift's Codable protocol
        if let savedData = defaults.data(forKey: StorageKey.completedGames),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: savedData)
        {
            completedMiniGames = decoded
        }
        
        if let savedData = defaults.data(forKey: StorageKey.miniGameScores),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: savedData)
        {
            miniGameScores = decoded
        }
        
        if let savedData = defaults.data(forKey: StorageKey.miniGamePercentages),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: savedData)
        {
            miniGamePercentages = decoded
        }
        
        if let savedData = defaults.data(forKey: StorageKey.achievements),
           let decoded = try? JSONDecoder().decode([String].self, from: savedData)
        {
            achievements = decoded
        }
        
        // Load experience level settings
        if let savedData = defaults.data(forKey: StorageKey.gameExperienceLevels),
           let decoded = try? JSONDecoder().decode([String: ExperienceLevel].self, from: savedData)
        {
            gameExperienceLevels = decoded
        } else {
            // Initialize default experience levels if not found
            gameExperienceLevels = [
                "Binary Game": .rookie,
                "Pixel Art Game": .rookie,
                "Color Game": .rookie
            ]
        }
        
        autoAdjustExperienceLevel = defaults.bool(forKey: StorageKey.autoAdjustExperienceLevel)
        
        if let savedData = defaults.data(forKey: StorageKey.gamePerformancePercentages),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: savedData)
        {
            gamePerformancePercentages = decoded
        }
    }
    
    // Reset all game states in UserDefaults
    private func resetAllGameStates() {
        let defaults = UserDefaults.standard
        
        // Remove known game phase keys
        for key in StorageKey.gamePhases {
            defaults.removeObject(forKey: key)
        }
        
        // Remove any keys that might be related to game progress
        let allKeys = defaults.dictionaryRepresentation().keys
        let progressKeys = allKeys.filter { key in
            key.contains("Game") &&
                (key.contains("Phase") ||
                    key.contains("Progress") ||
                    key.contains("State") ||
                    key.contains("Completed"))
        }
        
        for key in progressKeys {
            defaults.removeObject(forKey: key)
        }
        
        // Ensure specific game phases are reset
        defaults.removeObject(forKey: "BinaryGameCurrentPhase")
        defaults.removeObject(forKey: "PixelGameCurrentPhase")
        defaults.removeObject(forKey: "ColorGameCurrentPhase")
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    // Notification sent when user data is updated
    static let userDataUpdated = Notification.Name("UserDataUpdated")
    
    // Notification sent when game progress is reset
    static let resetGameProgress = Notification.Name("ResetGameProgress")
}
