const nodemailer = require('nodemailer');

// Create reusable transporter
let transporter = null;

const initializeEmailService = () => {
  // For development, use Gmail SMTP or other service
  // In production, configure with actual SMTP credentials
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER || process.env.EMAIL_USER,
      pass: process.env.SMTP_PASS || process.env.EMAIL_PASSWORD
    }
  });

  // Verify connection
  transporter.verify((error, success) => {
    if (error) {
      console.error('Email service initialization error:', error.message);
      console.warn('⚠️  Email service not configured. Email sending will be disabled.');
    } else {
      console.log('✅ Email service ready');
    }
  });
};

// Initialize on module load
if (process.env.SMTP_USER || process.env.EMAIL_USER) {
  initializeEmailService();
} else {
  console.warn('⚠️  Email credentials not configured. Set SMTP_USER and SMTP_PASS in config.env');
}

/**
 * Send email to a single recipient
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} html - Email HTML content
 * @param {string} text - Email plain text content (optional)
 * @returns {Promise}
 */
const sendEmail = async (to, subject, html, text = null) => {
  if (!transporter) {
    console.warn('Email service not initialized. Skipping email send.');
    return { success: false, error: 'Email service not configured' };
  }

  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || process.env.SMTP_USER || 'noreply@lalamove.com',
      to: to,
      subject: subject,
      html: html,
      text: text || html.replace(/<[^>]*>/g, '') // Strip HTML tags for text version
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending email:', error.message);
    return { success: false, error: error.message };
  }
};

/**
 * Send email to multiple recipients (with queue to avoid overwhelming server)
 * @param {Array<string>} recipients - Array of email addresses
 * @param {string} subject - Email subject
 * @param {string} html - Email HTML content
 * @param {string} text - Email plain text content (optional)
 * @param {number} batchSize - Number of emails to send concurrently (default: 5)
 * @param {number} delayMs - Delay between batches in milliseconds (default: 1000)
 * @returns {Promise<{success: number, failed: number, results: Array}>}
 */
const sendBulkEmail = async (recipients, subject, html, text = null, batchSize = 5, delayMs = 1000) => {
  if (!transporter) {
    console.warn('Email service not initialized. Skipping bulk email send.');
    return { success: 0, failed: recipients.length, results: [] };
  }

  const results = [];
  let successCount = 0;
  let failedCount = 0;

  // Process in batches to avoid overwhelming the server
  for (let i = 0; i < recipients.length; i += batchSize) {
    const batch = recipients.slice(i, i + batchSize);
    
    // Send batch concurrently
    const batchPromises = batch.map(async (to) => {
      const result = await sendEmail(to, subject, html, text);
      return { to, ...result };
    });

    const batchResults = await Promise.all(batchPromises);
    results.push(...batchResults);

    // Count successes and failures
    batchResults.forEach(result => {
      if (result.success) {
        successCount++;
      } else {
        failedCount++;
      }
    });

    // Delay before next batch (except for last batch)
    if (i + batchSize < recipients.length) {
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }

  console.log(`Bulk email completed: ${successCount} sent, ${failedCount} failed`);
  return { success: successCount, failed: failedCount, results };
};

module.exports = {
  sendEmail,
  sendBulkEmail,
  initializeEmailService
};

