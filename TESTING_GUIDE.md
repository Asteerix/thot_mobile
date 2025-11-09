# TESTING GUIDE - THOT MOBILE APP
**Quick Reference for Manual Testing**

---

## PRE-TESTING SETUP

### Requirements
- iOS device or simulator (iOS 12+)
- Android device or emulator (Android 5.0+)
- Stable internet connection
- Test accounts:
  - Journalist account (verified)
  - Regular user account

### Test Data Preparation
- Prepare test media files:
  - Image (1:1): 1080x1080, < 10MB, .jpg
  - Image (16:9): 1920x1080, < 10MB, .jpg
  - Image (9:16): 1080x1920, < 10MB, .jpg
  - Video (16:9): < 5min, < 500MB, .mp4
  - Video (9:16): < 60s, < 500MB, .mp4
  - Audio: < 100MB, .mp3 or .m4a

---

## TEST 1: PODCAST UPLOAD & PLAYBACK (15 min)

### Objective
Verify that podcasts can be uploaded and played correctly.

### Steps

1. **Login as Journalist**
   - Open app
   - Tap "Se connecter"
   - Enter journalist credentials
   - Verify successful login

2. **Navigate to New Publication**
   - Tap "+" button (bottom navigation)
   - Verify "Nouvelle publication" screen appears

3. **Select Domain**
   - Scroll through domain list
   - Tap "Politique" (or any domain)
   - Verify domain is selected (blue border)

4. **Select Format**
   - Scroll to format section
   - Tap "Podcast"
   - Verify format is selected (purple border)
   - Tap "Continuer" button

5. **Upload Audio File**
   - Tap "Ajouter un fichier audio"
   - Select MP3/M4A file (< 100MB)
   - Wait for file selection
   - **VERIFY:** Audio duration detected and displayed
   - **VERIFY:** File name shown
   - **VERIFY:** Play/pause button appears

6. **Test Audio Preview (Optional)**
   - Tap play button on audio preview
   - **VERIFY:** Audio plays
   - Tap pause button
   - **VERIFY:** Audio pauses
   - Drag seek bar
   - **VERIFY:** Seeking works

7. **Upload Thumbnail**
   - Tap "Ajouter une image"
   - Select square image (1:1 ratio, < 10MB)
   - **VERIFY:** Thumbnail preview appears
   - **VERIFY:** Image fills square container

8. **Fill Metadata**
   - Enter title: "Test Podcast [Current Date]"
   - **VERIFY:** Character count appears (min 5 chars)
   - Enter description: "This is a test podcast to verify the upload and playback functionality."
   - **VERIFY:** Character count appears (min 10 chars)

9. **Publish Podcast**
   - Tap "Publier" button
   - **VERIFY:** Upload progress dialog appears
   - **VERIFY:** Progress percentage updates
   - Wait for upload to complete (~30s-2min depending on file size)
   - **VERIFY:** Success message appears
   - **VERIFY:** Navigation to feed occurs

10. **Find Podcast in Feed**
    - Scroll through feed
    - Locate newly published podcast
    - **VERIFY:** Microphone icon (🎙️) on top-left
    - **VERIFY:** Green badge with "PODCAST" label
    - **VERIFY:** Thumbnail displayed
    - **VERIFY:** Title and description visible
    - **VERIFY:** Author name and avatar shown

11. **Open Podcast Detail**
    - Tap on podcast card
    - **VERIFY:** Podcast detail screen opens
    - **VERIFY:** Full title and description visible
    - **VERIFY:** Audio player controls appear
    - **VERIFY:** Play/pause button present
    - **VERIFY:** Duration displayed

12. **Test Playback**
    - Tap play button
    - **VERIFY:** Audio starts playing
    - **VERIFY:** Progress bar moves
    - **VERIFY:** Current time updates
    - Tap pause button
    - **VERIFY:** Audio pauses
    - Drag seek bar
    - **VERIFY:** Audio jumps to new position
    - Tap play again
    - **VERIFY:** Audio resumes from new position

13. **Test Interactions**
    - Tap like button
    - **VERIFY:** Heart fills with red
    - **VERIFY:** Like count increments
    - Tap like again
    - **VERIFY:** Heart becomes outline
    - **VERIFY:** Like count decrements
    - Tap comment icon
    - **VERIFY:** Comments screen opens
    - Add a test comment
    - **VERIFY:** Comment appears
    - Go back to podcast
    - **VERIFY:** Comment count updated

### Expected Results
- ✅ Podcast uploaded successfully
- ✅ Audio duration detected
- ✅ Thumbnail displayed correctly
- ✅ Podcast appears in feed with microphone icon
- ✅ Audio playback works smoothly
- ✅ All interactions (like, comment) functional

### Known Issues
- None currently

---

## TEST 2: VIDEO UPLOAD & PLAYBACK (15 min)

### Steps

1. **Navigate to New Publication**
   - Tap "+" button
   - Select "Science" domain
   - Select "Vidéo" format
   - Tap "Continuer"

2. **Upload Video**
   - Tap "Ajouter une vidéo"
   - Select 16:9 video (< 5min, < 500MB)
   - **VERIFY:** Video preview appears
   - **VERIFY:** Duration detected
   - **VERIFY:** Play button overlay shown

3. **Upload Thumbnail**
   - Tap "Ajouter une image"
   - Select 16:9 image
   - **VERIFY:** Thumbnail preview appears

4. **Fill Metadata**
   - Enter title: "Test Video [Date]"
   - Enter description: "Test video upload"

5. **Publish**
   - Tap "Publier"
   - Wait for upload (1-3 min)
   - **VERIFY:** Success and navigation to feed

6. **Find in Feed**
   - **VERIFY:** Play button (▶️) overlay on thumbnail
   - **VERIFY:** Red badge with "VIDÉO" label
   - **VERIFY:** Thumbnail displayed

7. **Test Playback**
   - Tap video card
   - **VERIFY:** Video player screen opens
   - Tap play button
   - **VERIFY:** Video plays
   - Test pause, seek, volume
   - **VERIFY:** All controls work

### Expected Results
- ✅ Video uploaded successfully
- ✅ Thumbnail displayed with play button
- ✅ Video playback works

---

## TEST 3: ARTICLE UPLOAD (10 min)

### Steps

1. **Navigate to New Publication**
   - Tap "+"
   - Select "Économie" domain
   - Select "Article" format
   - Tap "Continuer"

2. **Upload Image**
   - Tap "Ajouter une image"
   - Select 1:1 or 16:9 image
   - **VERIFY:** Image preview appears

3. **Fill Metadata**
   - Enter title: "Test Article [Date]"
   - Enter content: (Write at least 50 characters of test text)

4. **Publish**
   - Tap "Publier"
   - Wait for upload
   - **VERIFY:** Success

5. **Find in Feed**
   - **VERIFY:** Article icon (📄) on badge
   - **VERIFY:** Blue badge with "ARTICLE" label
   - **VERIFY:** Image displayed

6. **Open Article**
   - Tap article card
   - **VERIFY:** Full article view
   - **VERIFY:** Title, content, image visible

### Expected Results
- ✅ Article published successfully
- ✅ Image displayed correctly
- ✅ Article readable in detail view

---

## TEST 4: QUESTION/POLL CREATION (10 min)

### Steps

1. **Navigate to New Publication**
   - Tap "+"
   - Select "Société" domain
   - Tap "Question" card
   - **VERIFY:** Question type selection appears

2. **Select Type**
   - Choose "Sondage" (Poll)
   - **VERIFY:** Navigation to question form

3. **Fill Question**
   - Enter question: "Quelle est votre opinion sur [topic]?"
   - Add option 1: "Très favorable"
   - Add option 2: "Favorable"
   - Add option 3: "Neutre"
   - Add option 4: "Défavorable"
   - **VERIFY:** All options added

4. **Upload Image (Optional)**
   - Tap "Ajouter une image"
   - Select 16:9 image
   - **VERIFY:** Image preview

5. **Publish**
   - Tap "Publier"
   - **VERIFY:** Success

6. **Find in Feed**
   - **VERIFY:** Question mark icon (❓) on badge
   - **VERIFY:** Orange badge with "QUESTION" label

7. **Test Voting**
   - Tap question card
   - **VERIFY:** Voting UI appears with options
   - Tap an option
   - **VERIFY:** Vote recorded
   - **VERIFY:** Results displayed (percentage or count)

### Expected Results
- ✅ Question/poll created successfully
- ✅ Voting UI functional
- ✅ Vote recorded and displayed

---

## TEST 5: SHORT VIDEO UPLOAD (10 min)

### Steps

1. **Navigate to Shorts**
   - Tap "Shorts" tab in bottom navigation
   - Tap "+" button

2. **Upload Short**
   - Tap "Ajouter une vidéo"
   - Select 9:16 video (< 60s)
   - **VERIFY:** Vertical video preview

3. **Upload Thumbnail**
   - Tap "Ajouter une miniature"
   - Select 9:16 image
   - **VERIFY:** Vertical thumbnail preview

4. **Add Caption**
   - Enter caption: "Test Short #test"

5. **Publish**
   - Tap "Publier"
   - Wait for upload
   - **VERIFY:** Success

6. **Find in Shorts Feed**
   - Navigate to Shorts tab
   - **VERIFY:** Short appears in vertical feed
   - Swipe up
   - **VERIFY:** Next short loads
   - Swipe down
   - **VERIFY:** Previous short loads

7. **Test Playback**
   - **VERIFY:** Short auto-plays
   - **VERIFY:** Video fills screen (9:16)
   - Tap to pause
   - **VERIFY:** Pauses
   - Tap to play
   - **VERIFY:** Resumes

### Expected Results
- ✅ Short uploaded successfully
- ✅ Vertical format (9:16) maintained
- ✅ Swipe navigation works
- ✅ Auto-play functional

---

## TEST 6: FEED INTERACTIONS (15 min)

### Objective
Test all interaction types in the feed.

### Like/Unlike Test

1. **Find any post in feed**
2. **Double-tap post image**
   - **VERIFY:** Heart animation appears
   - **VERIFY:** Like count increments
   - **VERIFY:** Heart button filled
3. **Tap heart button**
   - **VERIFY:** Heart becomes outline
   - **VERIFY:** Like count decrements

### Comment Test

1. **Tap comment icon on post**
   - **VERIFY:** Comments screen opens
2. **Add comment**
   - Enter text: "Test comment"
   - Tap send button
   - **VERIFY:** Comment appears in list
   - **VERIFY:** Comment count on post increments
3. **Reply to comment**
   - Tap reply icon on a comment
   - Enter text: "Test reply"
   - Tap send
   - **VERIFY:** Reply appears indented
4. **Like comment**
   - Tap like icon on comment
   - **VERIFY:** Like count increments

### Follow Test

1. **Find post from another journalist**
2. **Tap "Follow" button**
   - **VERIFY:** Button changes to "Following"
   - **VERIFY:** Button color changes
3. **Tap journalist avatar**
   - **VERIFY:** Navigate to profile
   - **VERIFY:** "Following" button shown
4. **Tap "Following" button**
   - **VERIFY:** Confirmation dialog appears
   - Confirm unfollow
   - **VERIFY:** Button changes to "Follow"

### Bookmark Test

1. **Tap bookmark icon on post**
   - **VERIFY:** Icon fills
   - **VERIFY:** "Saved" message appears
2. **Navigate to Profile → Saved Content**
   - **VERIFY:** Post appears in saved list
3. **Return to feed**
4. **Tap bookmark icon again**
   - **VERIFY:** Icon becomes outline
   - **VERIFY:** "Removed from saved" message
5. **Check saved content**
   - **VERIFY:** Post removed from saved list

### Political Orientation Vote Test

1. **Tap political badge on post**
   - **VERIFY:** Voting dialog appears
2. **Select orientation**
   - Choose "Progressive"
   - **VERIFY:** Vote recorded
   - **VERIFY:** Badge color updates (if dominant view changes)
3. **Tap badge again**
   - **VERIFY:** Shows vote distribution
   - **VERIFY:** Your vote highlighted

### Expected Results
- ✅ All interactions functional
- ✅ Real-time updates working
- ✅ UI feedback clear and immediate

---

## TEST 7: SEARCH & NAVIGATION (10 min)

### Search Test

1. **Tap search icon**
   - **VERIFY:** Search screen appears
2. **Enter query: "politique"**
   - **VERIFY:** Results appear
   - **VERIFY:** Posts, journalists, or both shown
3. **Apply filters**
   - Select "Articles" type
   - **VERIFY:** Only articles shown
   - Select "Politique" domain
   - **VERIFY:** Results filtered
4. **Tap search result**
   - **VERIFY:** Navigate to post detail

### Profile Navigation Test

1. **Navigate to own profile**
   - Tap profile tab
   - **VERIFY:** Profile screen appears
   - **VERIFY:** Posts grid shown
2. **Tap "Edit Profile"**
   - **VERIFY:** Edit form appears
   - Change bio
   - Tap save
   - **VERIFY:** Profile updated
3. **Tap "Followers"**
   - **VERIFY:** Followers list appears
4. **Tap "Following"**
   - **VERIFY:** Following list appears

### Settings Navigation Test

1. **Navigate to Settings**
   - Tap settings icon
   - **VERIFY:** Settings screen appears
2. **Test each setting item**
   - Tap "Notification Preferences"
   - **VERIFY:** Preferences screen appears
   - Go back
   - Tap "Privacy Policy"
   - **VERIFY:** Policy screen appears
   - Go back

### Expected Results
- ✅ Search works with filters
- ✅ Profile navigation smooth
- ✅ Settings accessible
- ✅ All navigation flows work

---

## TEST 8: NOTIFICATIONS (10 min)

### Objective
Test notification delivery and navigation.

### Setup
- Use two devices or accounts
- Device A: Your account
- Device B: Another account

### Test Steps

1. **Device B: Like your post**
   - Find a post by Device A user
   - Like the post
2. **Device A: Check notifications**
   - **VERIFY:** Notification appears
   - **VERIFY:** Unread badge on notifications icon
   - Tap notification
   - **VERIFY:** Navigate to post

3. **Device B: Comment on your post**
   - Add a comment
4. **Device A: Check notifications**
   - **VERIFY:** Comment notification appears
   - Tap notification
   - **VERIFY:** Navigate to comments section

5. **Device B: Follow you**
   - Go to Device A's profile
   - Tap follow
6. **Device A: Check notifications**
   - **VERIFY:** Follow notification appears
   - Tap notification
   - **VERIFY:** Navigate to follower's profile

7. **Mark as Read Test**
   - Tap on a notification
   - Go back to notifications list
   - **VERIFY:** Notification marked as read
   - **VERIFY:** Unread count decrements

8. **Delete Notification Test**
   - Swipe left on notification (iOS) or long-press (Android)
   - Tap delete
   - **VERIFY:** Notification removed

### Expected Results
- ✅ Notifications delivered in real-time
- ✅ Unread badge updates correctly
- ✅ Navigation from notifications works
- ✅ Mark as read/delete functional

---

## TEST 9: ERROR HANDLING (15 min)

### Offline Mode Test

1. **Turn off WiFi and mobile data**
2. **Open app**
   - **VERIFY:** "No internet connection" banner appears
3. **Try to load feed**
   - **VERIFY:** Error message shown
   - **VERIFY:** Retry button present
4. **Turn on internet**
5. **Tap retry**
   - **VERIFY:** Feed loads successfully

### File Size Error Test

1. **Try to upload file > 100MB (podcast)**
   - **VERIFY:** Error message: "File too large. Maximum size allowed is 100MB"
   - **VERIFY:** Upload prevented

2. **Try to upload video > 500MB**
   - **VERIFY:** Error message: "File too large. Maximum size allowed is 500MB"

### Invalid File Type Test

1. **Try to upload .pdf as article image**
   - **VERIFY:** Error message: "Invalid file type. Expected image file (jpeg, png, webp)"
   - **VERIFY:** File rejected

2. **Try to upload .txt as audio**
   - **VERIFY:** Error message: "Invalid file type. Expected audio file"

### Form Validation Test

1. **Try to publish article with empty title**
   - **VERIFY:** Error message: "Titre requis (min 5 caractères)"
   - **VERIFY:** Submit prevented

2. **Try to publish with title < 5 chars**
   - **VERIFY:** Error message shown
   - **VERIFY:** Submit prevented

3. **Try to publish article with no image**
   - **VERIFY:** Error message: "Éléments manquants: image"

### Network Error Test

1. **Start upload, then disconnect internet**
   - **VERIFY:** Upload fails with error
   - **VERIFY:** Retry option available
2. **Reconnect internet**
3. **Tap retry**
   - **VERIFY:** Upload resumes or restarts

### Expected Results
- ✅ All errors handled gracefully
- ✅ User-friendly error messages in French
- ✅ Clear retry/recovery options
- ✅ No app crashes

---

## TEST 10: REAL-TIME UPDATES (15 min)

### Setup
- Two devices (Device A and Device B)
- Both logged in to different accounts
- Both viewing same post

### Like Update Test

1. **Device A: Open a post**
2. **Device B: Like the same post**
3. **Device A: Check like count**
   - **VERIFY:** Like count increments in real-time (< 2 seconds)
   - **VERIFY:** Heart animation (optional)

### Comment Update Test

1. **Both devices: View same post**
2. **Device B: Add comment**
3. **Device A: Check comment count**
   - **VERIFY:** Comment count increments in real-time
4. **Device A: Open comments**
   - **VERIFY:** New comment appears

### Political Vote Update Test

1. **Both devices: View same post**
2. **Device B: Vote on political orientation**
3. **Device A: Check political badge**
   - **VERIFY:** Vote distribution updates
   - **VERIFY:** Badge color changes (if dominant view changed)

### Profile Update Test

1. **Device A: Edit profile (change avatar)**
2. **Device B: View Device A's profile**
   - **VERIFY:** Avatar updates in real-time

### Expected Results
- ✅ All updates appear in < 2 seconds
- ✅ No page refresh needed
- ✅ Smooth animations
- ✅ Consistent across all devices

---

## REGRESSION TEST CHECKLIST

Run this after any major changes:

### Core Features
- [ ] User registration works
- [ ] User login works
- [ ] Logout works
- [ ] Password reset works

### Content Creation
- [ ] Article upload works
- [ ] Video upload works
- [ ] Podcast upload works
- [ ] Question creation works
- [ ] Short upload works

### Content Display
- [ ] Feed loads and scrolls
- [ ] All post types display correctly
- [ ] Shorts feed works (vertical swipe)
- [ ] Post detail screens open

### Interactions
- [ ] Like/unlike works
- [ ] Comment/reply works
- [ ] Follow/unfollow works
- [ ] Bookmark/unbookmark works
- [ ] Political voting works

### Navigation
- [ ] Bottom navigation works (Feed, Shorts, +, Notifications, Profile)
- [ ] Search works
- [ ] Profile navigation works
- [ ] Settings accessible
- [ ] Back navigation works

### Error Handling
- [ ] Offline mode shows error
- [ ] File size errors shown
- [ ] File type errors shown
- [ ] Form validation works
- [ ] Empty states shown

### Performance
- [ ] Feed loads in < 3 seconds
- [ ] Images load progressively
- [ ] Videos buffer smoothly
- [ ] No UI lag or freezing
- [ ] App doesn't crash

---

## PERFORMANCE BENCHMARKS

### Load Times (Target)
- Feed initial load: < 2 seconds
- Post detail: < 1 second
- Image load: < 2 seconds
- Video buffer start: < 3 seconds
- Search results: < 1 second

### Upload Times (Estimated)
- Image (10MB): 5-15 seconds
- Video (100MB): 30-60 seconds
- Video (500MB): 2-5 minutes
- Audio (50MB): 15-30 seconds

### Real-Time Updates
- Like/comment updates: < 2 seconds
- Notification delivery: < 2 seconds
- Profile updates: < 2 seconds

---

## BUG REPORT TEMPLATE

When you find a bug, document it like this:

**Title:** [Short description of bug]

**Severity:** Critical / High / Medium / Low

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Third step]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happens]

**Environment:**
- Device: [iPhone 14 / Samsung Galaxy S21]
- OS Version: [iOS 16.0 / Android 12]
- App Version: [1.0.0]
- Network: [WiFi / 4G / 5G]

**Screenshots/Videos:**
[Attach if applicable]

**Additional Notes:**
[Any other relevant information]

---

## TEST COMPLETION REPORT

After completing all tests, fill out:

**Tester Name:** _________________
**Date:** _________________
**App Version:** _________________
**Device Used:** _________________

### Test Results Summary

| Test | Status | Issues Found |
|------|--------|--------------|
| Podcast Upload | ✅ / ⚠️ / ❌ | [List issues] |
| Video Upload | ✅ / ⚠️ / ❌ | [List issues] |
| Article Upload | ✅ / ⚠️ / ❌ | [List issues] |
| Question Creation | ✅ / ⚠️ / ❌ | [List issues] |
| Short Upload | ✅ / ⚠️ / ❌ | [List issues] |
| Feed Interactions | ✅ / ⚠️ / ❌ | [List issues] |
| Search & Navigation | ✅ / ⚠️ / ❌ | [List issues] |
| Notifications | ✅ / ⚠️ / ❌ | [List issues] |
| Error Handling | ✅ / ⚠️ / ❌ | [List issues] |
| Real-Time Updates | ✅ / ⚠️ / ❌ | [List issues] |

**Legend:**
- ✅ Passed (all tests passed)
- ⚠️ Passed with minor issues (non-critical bugs found)
- ❌ Failed (critical bugs or features not working)

### Overall Assessment

**Ready for Production:** Yes / No / Needs Work

**Critical Issues:** [Number]

**High Priority Issues:** [Number]

**Medium/Low Issues:** [Number]

**Recommendations:**
[Your recommendations for next steps]

**Sign-off:**

Tester: _________________ Date: _________

QA Lead: _________________ Date: _________

Product Owner: _________________ Date: _________

---

**End of Testing Guide**
