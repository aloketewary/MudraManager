# Production Plugins

## Available Plugins

### 1. SMS Alert Plugin
**ID**: `com.mudra.sms_alert`  
**Description**: Get notified when money is credited via SMS

**Features**:
- Detects "credited" keyword in SMS
- Shows notification with amount
- Works with all bank SMS formats

**Use Case**: Never miss when money arrives in your account

---

### 2. Budget Guard Plugin
**ID**: `com.mudra.budget_guard`  
**Description**: Alert when budget limit is exceeded

**Features**:
- Monitors all budget categories
- Instant notification when limit crossed
- Helps prevent overspending

**Use Case**: Stay within your monthly budget limits

---

### 3. Goal Tracker Plugin
**ID**: `com.mudra.goal_tracker`  
**Description**: Get notified when financial goals are achieved

**Features**:
- Tracks savings goals
- Celebrates achievements
- Motivates financial discipline

**Use Case**: Reach your financial goals faster

---

## How Plugins Work

1. **Event-Driven**: Plugins react to app events (SMS, transactions, budgets)
2. **Sandboxed**: Plugins can only use secure API methods
3. **Toggleable**: Enable/disable anytime from Settings → Plugins
4. **Offline**: All plugins bundled with app, no downloads

## Plugin States

- **Enabled**: Plugin is active and processing events
- **Disabled**: Plugin is installed but inactive

## Managing Plugins

1. Go to **Profile → Plugins**
2. Toggle switch to enable/disable
3. Changes take effect immediately

## Technical Details

- All plugins extend `MudraPlugin`
- Secure API access via `MudraApi`
- State persisted in SharedPreferences
- No network access required
