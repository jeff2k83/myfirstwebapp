# N8N Disciple Program Workflow

## Overview
This workflow automates weekly attendance reminders for the Disciple Program. It runs every Wednesday at 3:00 PM and sends personalized reminder emails to all students in both the SOR (School of Revival) and DOR (Discipleship of Revival) programs.

## Workflow Description

### Flow Diagram
```
[Node 1: Every Wednesday 3pm]  (Schedule Trigger)
        ↓
[Node 2: Read SOR Students]  (Google Sheets)
        ↓
[Node 3: Read DOR Students]  (Google Sheets)
        ↓
[Node 4: Merge All Students]  (Merge)
        ↓
[Node 5: Calculate Current Week]  (Code)
        ↓
[Node 6: Process One Student]  (Split In Batches)
        ↓
[Node 7: Send Attendance Reminder]  (Gmail)
        ↓
[Node 8: Wait 1 Second]  (Wait)
        ↓
        └──────→ (loops back to Node 6)
```

### Node Details

1. **Every Wednesday 3pm** - Schedule Trigger
   - Runs every Wednesday at 15:00 (3:00 PM)
   - Cron expression: `0 15 * * 3`

2. **Read SOR Students** - Google Sheets
   - Reads all student records from the SOR spreadsheet
   - Retrieves student information including name and email

3. **Read DOR Students** - Google Sheets
   - Reads all student records from the DOR spreadsheet
   - Retrieves student information including name and email

4. **Merge All Students** - Merge Node
   - Combines both SOR and DOR student lists into a single dataset
   - Ensures all students receive reminders regardless of program

5. **Calculate Current Week** - Code Node
   - Calculates the current week number based on program start date
   - Adds week number and reminder date to each student record
   - Default start date: January 1, 2026 (configurable)

6. **Process One Student** - Split In Batches
   - Processes students one at a time
   - Prevents rate limiting by Gmail API
   - Batch size: 1

7. **Send Attendance Reminder** - Gmail
   - Sends personalized HTML email to each student
   - Includes current week number
   - Contains link to Google Forms attendance submission
   - Professional HTML formatting with call-to-action button

8. **Wait 1 Second** - Wait Node
   - Pauses for 1 second between emails
   - Further prevents rate limiting
   - Loops back to process next student

## Setup Instructions

### Prerequisites
- N8N instance (hosted or self-hosted)
- Google Sheets with student data
- Gmail account for sending emails
- Google Form for attendance submission

### Step 1: Import Workflow
1. Log in to your N8N instance
2. Click on "Workflows" in the left sidebar
3. Click "Import from File" or "Import from URL"
4. Select the `disciple-program-workflow.json` file
5. The workflow will be imported with all nodes configured

### Step 2: Configure Google Sheets Credentials
1. Click on "Credentials" in the left sidebar
2. Add new credentials for "Google Sheets OAuth2"
3. Follow the authentication flow to connect your Google account
4. Note the credential ID for later use

### Step 3: Configure Gmail Credentials
1. In "Credentials", add new credentials for "Gmail OAuth2"
2. Authenticate with the Gmail account you want to use for sending
3. Note the credential ID

### Step 4: Update Workflow Configuration

#### Node 2 & 3: Google Sheets Configuration
1. Click on "Read SOR Students" node
2. Replace `YOUR_SPREADSHEET_ID_HERE` with your actual Google Sheets ID
   - Find this in the URL: `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID_HERE/edit`
3. Select the correct sheet name (e.g., "SOR Students", "Sheet1")
4. Select your Google Sheets credential
5. Repeat for "Read DOR Students" node with the DOR spreadsheet

**Required Sheet Columns:**
- `name` or `firstName` - Student's name
- `email` - Student's email address

#### Node 5: Calculate Current Week
1. Click on "Calculate Current Week" node
2. Update the `startDate` variable to your program start date
   - Default: `'2026-01-01'`
   - Format: `'YYYY-MM-DD'`

#### Node 7: Gmail Configuration
1. Click on "Send Attendance Reminder" node
2. Replace `YOUR_GOOGLE_FORM_LINK_HERE` with your actual Google Form URL
3. Select your Gmail credential
4. Customize the email template as needed

### Step 5: Test the Workflow
1. Click "Execute Workflow" to test manually
2. Check that emails are sent correctly
3. Verify the email content and formatting
4. Ensure all students receive emails

### Step 6: Activate the Workflow
1. Click the toggle at the top of the workflow to "Active"
2. The workflow will now run automatically every Wednesday at 3:00 PM

## Customization Options

### Change Schedule
Edit the cron expression in Node 1:
- Current: `0 15 * * 3` (Wednesday 3:00 PM)
- Examples:
  - `0 9 * * 1` - Monday 9:00 AM
  - `0 18 * * 5` - Friday 6:00 PM
  - `0 12 * * 1,3,5` - Monday, Wednesday, Friday at noon

### Adjust Wait Time
Change the wait duration in Node 8:
- Current: 1 second
- Increase if you experience rate limiting
- Decrease to send emails faster

### Customize Email Template
Edit the HTML in Node 7:
- Update subject line
- Modify email body
- Change button styling
- Add additional information

### Modify Week Calculation
Update the JavaScript code in Node 5:
- Change start date
- Adjust week calculation logic
- Add custom date formatting

## Troubleshooting

### Emails Not Sending
- Verify Gmail credentials are valid and authorized
- Check Gmail sending limits (500 emails/day for free accounts)
- Ensure student email addresses are valid

### Wrong Week Number
- Verify the `startDate` in Node 5 is correct
- Check system timezone settings in N8N

### Missing Students
- Confirm Google Sheets credentials have read access
- Verify sheet names match exactly
- Check that all required columns exist

### Rate Limiting Errors
- Increase wait time in Node 8
- Reduce batch size if needed
- Check Gmail API quotas

## Google Sheets Format

### Expected Sheet Structure

```
| Name          | Email                    | Program |
|---------------|--------------------------|---------|
| John Doe      | john@example.com         | SOR     |
| Jane Smith    | jane@example.com         | SOR     |
| Bob Johnson   | bob@example.com          | DOR     |
```

**Required Columns:**
- `name` or `firstName` - Student's name (used in email greeting)
- `email` - Student's email address (must be valid)

**Optional Columns:**
- `program` - Program name (SOR/DOR)
- `phone` - Phone number
- `startDate` - Enrollment date
- Any other custom fields

## Support

For issues or questions:
1. Check N8N documentation: https://docs.n8n.io
2. Review N8N community forum: https://community.n8n.io
3. Check Google Sheets/Gmail API status

## License

This workflow is provided as-is for the Disciple Program.

## Version History

- **v1.0** (2026-01-15) - Initial workflow creation
  - Schedule trigger for Wednesday 3:00 PM
  - Read from two Google Sheets sources
  - Merge and process students
  - Send personalized Gmail reminders
  - Rate limiting with 1-second delay
