# TECHSTACK.md

## Tech Stack

| Category | Technology Used | Purpose in App |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform mobile/desktop UI framework |
| Language | Dart 3.11+ | Primary development language |
| Authentication | Firebase Auth | User sign-up, login, password reset |
| Database | Cloud Firestore | Real-time NoSQL database for users, posts, notifications |
| File Storage | Firebase Storage | Upload and serve post media (photos/videos) |
| State Management | Flutter setState | Local UI state management |
| Local Storage | Shared Preferences | Persist "Remember Me" login preference |
| Fonts | Google Fonts | App-wide typography (Baloo2, Nunito, JosefinSans, Modak, etc.) |
| Media Picking | image_picker | Pick photos and videos from device gallery |
| Video Playback | video_player | Play videos in the home feed and post modal |
| Video Compression | video_compress | Compress videos before upload to Firebase Storage |
| Gallery Save | gal | Save media from posts to the device gallery |
| HTTP Client | http (dart:io) | Download media bytes for gallery saving |
| UI Icons | cupertino_icons | iOS-style icons used in toggle switches |

---

## Firebase Schema

### Collection: `users`

| Field Name | Data Type | Description |
|---|---|---|
| `uid` | String | Firebase Auth UID (document ID) |
| `fullName` | String | User's full display name |
| `username` | String | Unique @nickname shown in the app |
| `email` | String | User's email address |
| `photoURL` | String | URL to profile photo (empty until uploaded) |
| `bio` | String | User biography/description |
| `isOnline` | Boolean | Whether the user is currently online |
| `createdAt` | Timestamp | Account creation timestamp |
| `mutedUsers` | Array\<String\> | List of user IDs whose notifications are muted |

---

### Collection: `posts`

| Field Name | Data Type | Description |
|---|---|---|
| `postId` | String | Document ID of the post |
| `userId` | String | UID of the post author |
| `username` | String | Username of the post author |
| `fullName` | String | Full name of the post author |
| `description` | String | Caption/text content of the post |
| `mediaURL` | String | Download URL of the uploaded photo or video |
| `mediaType` | String | Type of media: `"photo"`, `"video"`, or `"none"` |
| `videoWidth` | Number | Width of the video in pixels (0 if not a video) |
| `videoHeight` | Number | Height of the video in pixels (0 if not a video) |
| `location` | String | Location tag attached to the post |
| `audience` | String | Audience setting: `"Feed"`, `"Group"`, or `"Lost and Found"` |
| `privacy` | String | Privacy setting: `"Only me"`, `"Friends"`, or `"Everyone"` |
| `likeCount` | Number | Total number of likes |
| `commentCount` | Number | Total number of comments |
| `createdAt` | Timestamp | Post creation timestamp |

---

### Sub-collection: `posts/{postId}/likes`

| Field Name | Data Type | Description |
|---|---|---|
| `userId` | String | UID of the user who liked the post (document ID) |
| `username` | String | Username of the liker |
| `fullName` | String | Full name of the liker |
| `createdAt` | Timestamp | When the like was created |

---

### Sub-collection: `posts/{postId}/comments`

| Field Name | Data Type | Description |
|---|---|---|
| `commentId` | String | Document ID of the comment |
| `userId` | String | UID of the commenter |
| `username` | String | Username of the commenter |
| `fullName` | String | Full name of the commenter |
| `text` | String | Comment text content |
| `likeCount` | Number | Number of likes on this comment |
| `createdAt` | Timestamp | When the comment was posted |
| `editedAt` | Timestamp | When the comment was last edited (null if never) |
| `replyToCommentId` | String | ID of the parent comment if this is a reply (null otherwise) |
| `replyToUsername` | String | Username of the user being replied to (null otherwise) |

---

### Sub-collection: `posts/{postId}/comments/{commentId}/likes`

| Field Name | Data Type | Description |
|---|---|---|
| `uid` | String | UID of the user who liked the comment (document ID) |
| `createdAt` | Timestamp | When the comment like was created |

---

### Collection: `notifications`

| Field Name | Data Type | Description |
|---|---|---|
| `toUserId` | String | UID of the notification recipient |
| `fromUserId` | String | UID of the user who triggered the notification |
| `fromUsername` | String | Username of the sender |
| `fromFullName` | String | Full name of the sender |
| `type` | String | Notification type: `"like"`, `"comment"`, or `"follow"` |
| `postId` | String | ID of the related post |
| `commentText` | String | Comment content (only for `"comment"` type) |
| `isRead` | Boolean | Whether the notification has been read |
| `createdAt` | Timestamp | When the notification was created |