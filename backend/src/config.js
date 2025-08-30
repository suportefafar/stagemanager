import "dotenv/config";

const config = {
  mongoDbUri: process.env.MONGO_DB_URI || "mongodb://localhost:27017/local",
  environment: process.env.ENVIRONMENT || "production",
  debugMode: process.env.DEBUG === "true" || process.env.DEBUG == 1,
  singleCycle:
    process.env.SINGLE_CYCLE === "true" || process.env.SINGLE_CYCLE == 1,
  timezone:
    process.env.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone,
  scrapeBaseURL: process.env.SCRAPE_BASE_URL || "https://www.google.com.br/",
  loginUser: process.env.LOGIN_USER || "",
  loginPassword: process.env.LOGIN_PASSWORD || "",
  sessionCookies: process.env.SESSION_COOKIES || "",
  scrapeTimes: process.env.SCRAPE_TIMES || "07:00", // Examples: '07:00', '07:00,18:00', etc
  maxItensToScrape: process.env.MAX_ITENS_TO_SCRAPE || 10,
  apiIntranetBaseUrl: process.env.API_INTRANET_BASE_URL || "http://127.0.0.1",
  noScrapeDelay:
    process.env.NO_SCRAPE_DELAY === "true" || process.env.NO_SCRAPE_DELAY == 1,
  scrapeDelay: process.env.SCRAPE_DELAY || 1,
  minIntranetTicketNumber: process.env.MIN_INTRANET_TICKET_NUMBER || 8800,
  mail_to_field: process.env.MAIL_TO_FIELD || "teste@teste.com",
  greaterIntranetTicketNumber: 15000, // This is for recognize DEMAI OSs on ticket descriptions. For more, see the README file
};

export default config;
