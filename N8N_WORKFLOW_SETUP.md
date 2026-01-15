# N8N Disciple Program - Weekly Attendance Workflow Setup Guide

## Overview
This workflow automatically sends weekly attendance reminders to all disciple program students every Wednesday at 3:00 PM.

## Workflow Details

**Workflow File**: `n8n-disciple-attendance-workflow.json`

**N8N Instance**: https://n8n.srv1139673.hstgr.cloud/workflow/RWKdnuhHJS4ifZo0

### Flow Description
1. **Schedule Trigger** - Runs every Wednesday at 3:00 PM
2. **Read SOR Students** - Fetches students from "SOR Leadership" sheet
3. **Read DOR Students** - Fetches students from "DOR Leadership" sheet
4. **Merge All Students** - Combines both student lists
5. **Calculate Current Week** - Adds week number and date info
6. **Process One Student** - Splits into individual student records
7. **Send Attendance Reminder** - Sends personalized email to each student
8. **Wait 1 Second** - Prevents Gmail rate limiting
9. **Loop Back** - Returns to Process One Student until all are sent

## Setup Instructions

### Step 1: Import Workflow to N8N

1. Go to your N8N instance: https://n8n.srv1139673.hstgr.cloud/
2. Click on **Workflows** in the left sidebar
3. Click **Import from File** or **Import from URL**
4. Select the `n8n-disciple-attendance-workflow.json` file
5. The workflow will be imported with all nodes configured

### Step 2: Configure Google Sheets Credentials

You need to set up Google Sheets OAuth2 credentials:

1. In N8N, go to **Credentials** menu
2. Click **Add Credential**
3. Select **Google Sheets OAuth2 API**
4. Follow the OAuth2 setup process:
   - Use your Google account that has access to the spreadsheet
   - Grant necessary permissions for reading sheets
5. Save the credential

### Step 3: Update Google Sheets Nodes

For both "Read SOR Students" and "Read DOR Students" nodes:

1. Click on the node
2. Under **Credential to connect with**, select the Google Sheets credential you just created
3. The spreadsheet is already configured:
   - **Spreadsheet ID**: 1joor7kwrSVZbGxOkpzoXWivY0NXGSya9qUL9HvaD4IM
   - **SOR Sheet Name**: "SOR Leadership"
   - **DOR Sheet Name**: "DOR Leadership"
4. Expected columns:
   - **Column A**: Name (student name)
   - **Column B**: Email (student email address)

### Step 4: Configure Gmail Credentials

1. In N8N, go to **Credentials** menu
2. Click **Add Credential**
3. Select **Gmail OAuth2**
4. Follow the OAuth2 setup process:
   - Use the Gmail account you want to send emails from
   - Grant necessary permissions for sending emails
5. Save the credential

### Step 5: Update Gmail Node

1. Click on the "Send Attendance Reminder" node
2. Under **Credential to connect with**, select the Gmail credential you created
3. The email template is pre-configured with:
   - Subject: "📋 Weekly Attendance Reminder - Week {weekNumber}"
   - HTML formatted message with personalized greeting
   - Link to attendance form
   - Professional styling

### Step 6: Activate the Workflow

1. Click the **Active** toggle in the top-right corner of the workflow editor
2. The workflow is now scheduled and will run automatically every Wednesday at 3:00 PM

## Configuration Details

### Google Sheets Structure

**Spreadsheet URL**: https://docs.google.com/spreadsheets/d/1joor7kwrSVZbGxOkpzoXWivY0NXGSya9qUL9HvaD4IM/edit

**Required Sheets**:
- SOR Leadership (Tab name in spreadsheet)
- DOR Leadership (Tab name in spreadsheet)

**Required Columns**:
| Column | Header | Description |
|--------|--------|-------------|
| A | Name | Student's full name |
| B | Email | Student's email address |

### Attendance Form

**Google Form URL**: https://docs.google.com/forms/d/e/1FAIpQLSc8HRhAj7a1XvmFWQ_IXQjEO6iwLeyYjYL7MIa7nsn4Y99QRg/viewform

This link is embedded in every reminder email sent to students.

### Schedule Details

**Cron Expression**: `0 15 * * 3`
- **Time**: 3:00 PM (15:00)
- **Day**: Wednesday (3)
- **Frequency**: Every week
- **Timezone**: Server timezone (configure in N8N settings if needed)

## Email Template Customization

The email template includes:
- Personalized greeting with student name
- Current week number
- Current date
- Call-to-action button linking to the attendance form
- Professional HTML formatting
- Footer with automation notice

To customize the email:
1. Click on the "Send Attendance Reminder" node
2. Edit the **message** parameter
3. Available variables:
   - `{{ $json.Name }}` - Student name
   - `{{ $json.Email }}` - Student email
   - `{{ $json.weekNumber }}` - Current week number
   - `{{ $json.currentDate }}` - Current date (formatted)
   - `{{ $json.formLink }}` - Attendance form URL

## Testing the Workflow

### Manual Test
1. Click **Execute Workflow** button in N8N
2. Check that:
   - Students are read from both sheets
   - They are merged correctly
   - Week number is calculated
   - Emails are sent to all students
   - Each email has a 1-second delay

### Check Execution History
1. Go to **Executions** in N8N
2. View past runs and their status
3. Check for any errors or failed nodes

## Troubleshooting

### Common Issues

**Issue**: No students fetched from Google Sheets
- **Solution**: Verify the sheet names are exactly "SOR Leadership" and "DOR Leadership"
- Check that columns A and B contain Name and Email data
- Ensure Google Sheets credential has proper permissions

**Issue**: Emails not sending
- **Solution**: Check Gmail credential is properly configured
- Verify the Gmail account has sending permissions
- Check if Gmail daily sending limit is reached (500 emails/day for free accounts)

**Issue**: Schedule not triggering
- **Solution**: Ensure workflow is **Active** (toggle in top-right)
- Check timezone settings in N8N match your expected time
- Verify cron expression is correct

**Issue**: Rate limiting errors
- **Solution**: Increase the wait time in "Wait 1 Second" node
- Consider using "Wait 2 Seconds" for larger student lists

### Error Notifications

Set up error workflow in N8N:
1. Go to **Settings** > **Error Workflow**
2. Create a workflow that sends you an email when this workflow fails
3. This ensures you're notified of any issues

## Maintenance

### Weekly Checks
- Verify workflow executed successfully every Wednesday
- Check execution logs for any errors
- Confirm all students received emails

### Monthly Reviews
- Review and update email template if needed
- Check student lists are up to date in Google Sheets
- Verify form link is still active

### Updates to Student Lists
- Simply update the Google Sheets (add/remove rows)
- No changes needed to the N8N workflow
- New students will automatically receive emails on next Wednesday

## Additional Features (Optional Enhancements)

Consider adding these features:
1. **Confirmation tracking**: Log which students opened/clicked the email
2. **Duplicate prevention**: Check if student already submitted before sending
3. **Custom schedules**: Different reminder times for different groups
4. **Slack notifications**: Alert admins when emails are sent
5. **Error handling**: Retry failed emails automatically

## Support

For issues with:
- **N8N platform**: Contact your N8N hosting support
- **Google Sheets**: Ensure proper sharing permissions
- **Gmail**: Check Google account settings and permissions
- **This workflow**: Review execution logs and error messages

## Workflow Statistics

- **Total Nodes**: 8
- **Estimated Execution Time**: ~1 second per student + processing time
- **Gmail Sending Rate**: 1 email per second (3,600 max per hour)
- **Weekly Execution**: Every Wednesday at 3:00 PM

---

**Created**: 2026-01-15
**Version**: 1.0
**Status**: Ready for deployment
