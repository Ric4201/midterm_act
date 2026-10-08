# CC 105 – Applications Development and Emerging Technologies
## Activity: Pick Your Own API (Future, Stream & REST API Integration)
**Divine Word College of Legazpi — School of Engineering and Computer Studies**

---

## 🎯 Project Overview
This Flutter application integrates a public REST API using both **`FutureBuilder`** and **`StreamBuilder`** constructs according to the midterm activity guidelines.

| Screen | Powered By | What it Shows | API Endpoint |
|---|---|---|---|
| **Screen 1: The Order** | `FutureBuilder` | Fetches a list of quotes once when the screen opens | `https://dummyjson.com/quotes?limit=15` |
| **Screen 2: The Belt** | `StreamBuilder` | Auto-updates every 5 seconds with a new random quote | `https://dummyjson.com/quotes/random` |

---

## 🛡️ API Ground Rules Compliance
- **100% Free, No API Key, No Credit Card Required**: Uses the open [DummyJSON Quotes API](https://dummyjson.com/docs/quotes).
- **Not JSONPlaceholder or Open-Meteo**: Selected as an approved independent public API.
- **Data Visibly Changes**: Screen 2 calls `/quotes/random` every 5 seconds so each tick delivers a fresh quote.
- **Server Rate Limit Friendly**: Requests are throttled to a respectful 5-second interval.

---

## 📋 Must-Haves Checklist

### Screen 1: The Order (`FutureBuilder`)
- [x] **Loads once on open**: `_quotesFuture` is initialized once in `initState()`, preventing endless re-fetching on widget rebuilds.
- [x] **Loading Spinner**: Displays a circular progress indicator while waiting for the HTTP response.
- [x] **Error Message & Retry Button**: Catches network/airplane mode errors and shows a dedicated Retry button.
- [x] **Empty State**: Displays a friendly message if the API returns an empty list.
- [x] **Real API Data as List**: Renders quote cards with quote text, author chip, and quote ID.

### Screen 2: The Belt (`StreamBuilder`)
- [x] **Updates on its own**: Periodically fetches new quotes every 5 seconds using a Dart `Timer.periodic`.
- [x] **Loading State**: Displays a loading screen before the first data arrives.
- [x] **Error State**: Shows an error banner if network fails (e.g., Airplane mode active).
- [x] **One failed fetch does NOT kill the stream**: Uses `StreamController.addError(e)` rather than closing the stream. When network is restored, the next 5-second tick resumes seamlessly!
- [x] **Conveyor Belt History**: Displays the newest quote prominently while keeping a rolling history of recent deliveries.

### Both Screens
- [x] **Typed Dart Objects**: All JSON responses are deserialized using `Quote.fromJson()` and `QuoteListResponse.fromJson()`.
- [x] **Status Code Check**: Validates `response.statusCode == 200` before decoding.
- [x] **Request Timeout**: All network calls enforce a 5-second timeout (`.timeout(Duration(seconds: 5))`).
- [x] **Survives Airplane-Mode Test**: Specifically catches `SocketException`, `TimeoutException`, and client errors to prevent app crashes when network is toggled off during live demo.

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, Material 3 theme, Tab navigation
├── models/
│   └── quote.dart              # Typed Quote & QuoteListResponse models (fromJson)
├── services/
│   └── quote_service.dart      # HTTP client, status checks, timeouts & StreamController
└── screens/
    ├── order_screen.dart       # Screen 1: FutureBuilder list implementation
    └── belt_screen.dart        # Screen 2: StreamBuilder periodic conveyor belt
test/
├── quote_service_test.dart     # Unit tests for JSON deserialization
└── widget_test.dart            # Smoke test for navigation & screens
```

---

## 🎤 Oral Defense Guide (Explaining the Code)

### 1. Why is the Future stored in `initState()` instead of inside `build()`?
> *"If `fetchQuotes()` were called directly inside the `build()` method, every time the screen redraws (like on screen rotation or theme change), it would trigger a new network request and cause endless refetching. By assigning `_quotesFuture = widget.quoteService.fetchQuotes()` in `initState()`, the Future executes exactly once when the screen opens."*

### 2. How does the Stream survive Airplane Mode without dying?
> *"In `QuoteService.getQuoteStream()`, we use a `StreamController.broadcast()`. When an individual fetch fails due to Airplane Mode (`SocketException`), we catch the error and invoke `controller.addError(error)` instead of `controller.close()`. This allows `StreamBuilder` to receive `snapshot.hasError` while keeping the stream pipeline open. When Airplane Mode is turned off, the periodic 5-second timer fires again, succeeds, and pushes new data with `controller.add(quote)`."*

### 3. How are status codes and timeouts handled?
> *"Every HTTP request uses `.timeout(const Duration(seconds: 5))`. We check `if (response.statusCode == 200)` before calling `jsonDecode()`. If the server returns 4xx or 5xx, or if the request times out or is offline, specific exceptions (`SocketException`, `TimeoutException`, `HttpException`) are caught and transformed into user-friendly messages."*

---

## 🚀 How to Run

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run tests**:
   ```bash
   flutter test
   ```

3. **Run on Windows Desktop / Chrome / Emulator**:
   ```bash
   flutter run -d windows
   # or
   flutter run -d chrome
   ```
