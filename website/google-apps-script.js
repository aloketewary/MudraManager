// Google Apps Script to add beta testers to Google Sheet
// Deploy this as a Web App and use the URL in your form

function doPost(e) {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Sheet1');
    const data = JSON.parse(e.postData.contents);
    
    // Add new row with only name and date (no email for security)
    sheet.appendRow([data.name, new Date()]);
    
    return ContentService.createTextOutput(JSON.stringify({
      status: 'success',
      message: 'Added to beta testers!'
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput('Beta Tester API is running');
}
