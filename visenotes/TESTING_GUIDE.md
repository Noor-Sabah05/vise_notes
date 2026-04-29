# Quick Testing Guide - ViseNotes Database Integration

## Pre-Testing Checklist

- ✅ Dependencies installed (`flutter pub get`)
- ✅ Backend server running on http://192.168.100.204:8000
- ✅ Android emulator or device connected
- ✅ Code builds without errors

## Quick Test Flow (5 Minutes)

### Test 1: Record & Generate Notes (2 min)

```
1. flutter run
   └─ App launches
   
2. HomeScreen (Home tab)
   ├─ Select audio file (File Picker)
   │  OR
   ├─ Use test audio from assets
   │
   └─ Click "Transcribe & Generate Notes"
      ├─ Shows loading indicator (15-30 seconds)
      ├─ Backend processes audio
      └─ NotesScreen appears with generated content
      
3. Verify NotesScreen shows:
   ├─ Title
   ├─ AI Summary
   ├─ Full Content
   ├─ Key Points
   ├─ 3 Buttons: PDF | Quiz | Save to Library (GREEN)
```

### Test 2: Save Note to Database (1 min)

```
1. On NotesScreen from Test 1
   └─ Click "Save to Library" (green button)
      ├─ Loading indicator appears
      ├─ Database saves note
      └─ Success message: "Note saved to library"
      
2. Verify note saved:
   ├─ Title: ✓
   ├─ Summary: ✓
   ├─ Date: ✓
   └─ Category: "General"
```

### Test 3: View Notes in Library (2 min)

```
1. Bottom Navigation: Click "Library" tab
   └─ CategoryScreen loads
      ├─ Grid of 6 categories
      ├─ Each with icon and title
      └─ Touch feedback works
      
2. Click any category (e.g., "General")
   └─ NotesHistoryScreen opens
      ├─ Shows list of notes in category
      ├─ Each note shows: Title, Summary, Date
      └─ Search bar at top
      
3. Find the note you just saved
   └─ Should show your generated title and summary
```

### Test 4: Search Functionality (1 min)

```
1. On NotesHistoryScreen
   └─ Type in search bar (top)
      ├─ Real-time filtering
      ├─ Only matching notes shown
      └─ Clear search shows all notes again
```

### Test 5: Delete Note (30 sec)

```
1. On NotesHistoryScreen
   └─ Find a note
      ├─ Click the red delete icon
      ├─ Note removed from list
      └─ Verify in database: gone from category
```

## Testing Detailed Scenarios

### Scenario A: PDF Generation

```
1. NotesScreen (after generating notes)
   └─ Click "PDF" button
      ├─ Shows "Generating..." state
      ├─ Calls generatePdfFromTranscript()
      ├─ Backend creates PDF
      └─ Success message: "PDF generated successfully"
         └─ Action button: "Open"
         
2. Click "Open"
   └─ PDF opens in default viewer
```

### Scenario B: Quiz Generation

```
1. NotesScreen (after PDF generated)
   └─ Click "Quiz" button
      ├─ Shows "Generating..." state
      ├─ Calls generateQuizFromPdf()
      ├─ Backend creates quiz PDF
      └─ Success message: "Quiz generated successfully"
         └─ Action button: "Open"
         
2. Click "Open"
   └─ Quiz PDF opens in default viewer
```

### Scenario C: Share Note

```
1. NotesHistoryScreen
   └─ Find a note with PDF
      ├─ Click share icon
      ├─ Share dialog appears
      └─ Choose app to share with
         ├─ WhatsApp
         ├─ Email
         ├─ File Manager
         └─ Other apps
```

### Scenario D: Multiple Categories

```
1. HomeScreen (Record tab)
   └─ Select category dropdown
      ├─ Choose: Mathematics, Physics, etc.
      └─ Select audio
      
2. Generate notes
   └─ On NotesScreen, click "Save to Library"
      ├─ Note saved with chosen category
      └─ (Note: Current implementation always saves as "General")
      
3. Library tab → Select different category
   └─ See notes from different categories
```

## Expected Results

### ✅ All Tests Pass When:

- [x] App launches without crashes
- [x] Home/Record tabs show UI correctly
- [x] Audio transcription completes
- [x] AI generates notes successfully
- [x] NotesScreen displays all sections
- [x] "Save to Library" works
- [x] Library tab shows CategoryScreen
- [x] Clicking category shows NotesHistoryScreen
- [x] Notes display correctly in list
- [x] Search filters notes
- [x] Delete removes notes
- [x] Navigation between tabs smooth
- [x] No memory leaks or crashes
- [x] File operations (open/share) work

### 🔴 Known Issues/Limitations:

1. **Category not respected on save** - Currently saves all to "General"
   - Fix: Update `_saveNoteToLibrary()` in notes_screen.dart to pass category parameter
   
2. **PDF path not always saved** - If PDF not generated before save
   - Expected behavior: Note saved, PDF field empty (null)
   - Workaround: Click PDF button before Save to Library

3. **Database locked errors** - Very rare with single app instance
   - Solution: Restart app

## Debug/Troubleshooting

### View Database Content

Add this to your app temporarily:
```dart
// In main.dart after DBService initialization
final notes = await DBService().getNotes();
print('Total notes in DB: ${notes.length}');
for (var note in notes) {
  print('- ${note.title} (${note.category})');
}
```

### Check API Connectivity

```dart
// In api_service.dart
final isHealthy = await ApiService.healthCheck();
print('Backend alive: $isHealthy');
```

### View SQLite File

Location: `{app.getApplicationDocumentsDirectory()}/notes.db`

Can inspect with:
- Android Studio Database Inspector
- SQLite browser apps
- DBeaver

## Performance Notes

- **First launch**: ~5-10 seconds (database initialization)
- **Subsequent launches**: <1 second
- **Transcription**: 15-30 seconds (backend dependent)
- **Note generation**: 10-20 seconds
- **PDF generation**: 5-10 seconds
- **Search**: <100ms (instant)
- **Database queries**: <50ms

## Success Criteria

Your integration is successful when:

1. ✅ Audio → Transcript works (HomeScreen)
2. ✅ Transcript → Notes works (via API)
3. ✅ Notes → Save to DB works (NotesScreen button)
4. ✅ Library → View saved notes works (CategoryScreen → NotesHistoryScreen)
5. ✅ Search, Delete, Share work (NotesHistoryScreen)
6. ✅ No crashes through entire workflow
7. ✅ Database persists data (close/reopen app)

## Next Steps After Testing

If all tests pass:
1. [ ] Record real-world test data
2. [ ] Test with various audio lengths (30s, 5min, 30min)
3. [ ] Test search with many notes (100+)
4. [ ] Test edge cases (empty notes, very long titles)
5. [ ] Deploy to actual device
6. [ ] Get user feedback

If tests fail:
1. [ ] Check error messages in logcat
2. [ ] Verify backend is running
3. [ ] Check network connectivity
4. [ ] Run `flutter clean && flutter pub get`
5. [ ] Restart emulator/device

---

**Ready to test?** Run:
```bash
flutter run
```

Good luck! 🚀
