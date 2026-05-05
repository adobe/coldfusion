<cfscript>
// ============================================
// SETUP: Place files in these locations
// ============================================
// {cf_root}/lib/opennlp-tools-2.3.0.jar
// {cf_root}/models/opennlp/en-token.bin
// {cf_root}/models/opennlp/en-pos-maxent.bin
// {cf_root}/models/opennlp/en-ner-person.bin

// ============================================
// EXAMPLE 1: Text Sentiment Analysis
// ============================================

sentimentAnalyzerClass = java{
    import opennlp.tools.tokenize.TokenizerME;
    import opennlp.tools.tokenize.TokenizerModel;
    import opennlp.tools.postag.POSTaggerME;
    import opennlp.tools.postag.POSModel;
    import java.io.FileInputStream;
    import java.util.Arrays;
    
    public class CustomerReviewAnalyzer implements java.util.function.Function {
        private TokenizerME tokenizer;
        private POSTaggerME posTagger;
        
        private java.util.Set<String> positiveWords;
        private java.util.Set<String> negativeWords;
        
        public CustomerReviewAnalyzer(String tokenizerPath, String posModelPath) {
            try {
                FileInputStream tokenizerStream = new FileInputStream(tokenizerPath);
                TokenizerModel tokenizerModel = new TokenizerModel(tokenizerStream);
                tokenizer = new TokenizerME(tokenizerModel);
                tokenizerStream.close();
                
                FileInputStream posStream = new FileInputStream(posModelPath);
                POSModel posModel = new POSModel(posStream);
                posTagger = new POSTaggerME(posModel);
                posStream.close();
                
                positiveWords = new java.util.HashSet<>(Arrays.asList(
                    "good", "great", "excellent", "amazing", "wonderful", "fantastic",
                    "perfect", "love", "best", "awesome", "brilliant", "outstanding",
                    "superb", "recommend", "happy", "satisfied", "pleased", "delighted",
                    "excited", "nice","pleasant"
                ));
                
                negativeWords = new java.util.HashSet<>(Arrays.asList(
                    "bad", "terrible", "horrible", "awful", "poor", "worst", "hate",
                    "disappointed", "waste", "useless", "broke", "defective", "cheap",
                    "fraud", "scam", "never", "not", "horrible", "disgusting"
                ));
                
            } catch(Exception e) {
                throw new RuntimeException("Failed to initialize analyzer: " + e.getMessage());
            }
        }
        
        @Override
        public Object apply(Object obj) {
            java.util.Map review = (java.util.Map)obj;
            String text = review.get("text").toString().toLowerCase();
            java.util.Map result = new java.util.HashMap();
            
            try {
                String[] tokens = tokenizer.tokenize(text);
                String[] tags = posTagger.tag(tokens);
                
                int positiveScore = 0;
                int negativeScore = 0;
                java.util.List<String> positiveWordsFound = new java.util.ArrayList<>();
                java.util.List<String> negativeWordsFound = new java.util.ArrayList<>();
                
                for(int i = 0; i < tokens.length; i++) {
                    String token = tokens[i].toLowerCase();
                    
                    if(positiveWords.contains(token)) {
                        positiveScore++;
                        positiveWordsFound.add(token);
                    }
                    if(negativeWords.contains(token)) {
                        negativeScore++;
                        negativeWordsFound.add(token);
                    }
                }
                
                String sentiment;
                double confidence;
                
                if(positiveScore > negativeScore) {
                    sentiment = "Positive";
                    confidence = (double)positiveScore / (positiveScore + negativeScore);
                } else if(negativeScore > positiveScore) {
                    sentiment = "Negative";
                    confidence = (double)negativeScore / (positiveScore + negativeScore);
                } else {
                    sentiment = "Neutral";
                    confidence = 0.5;
                }
                
                result.put("reviewId", review.get("reviewId"));
                result.put("customerName", review.get("customerName"));
                result.put("sentiment", sentiment);
                result.put("confidence", confidence);
                result.put("positiveScore", positiveScore);
                result.put("negativeScore", negativeScore);
                result.put("positiveWords", positiveWordsFound);
                result.put("negativeWords", negativeWordsFound);
                result.put("totalWords", tokens.length);
                result.put("text", review.get("text"));
                
            } catch(Exception e) {
                result.put("error", e.getMessage());
                result.put("reviewId", review.get("reviewId"));
            }
            
            return result;
        }
    }
};

// ============================================
// Initialize Analyzer
// ============================================
writeOutput("<h1>Apache OpenNLP - Customer Review Analysis</h1>");

tokenizerPath = expandPath("./models/opennlp/en-token.bin");
posModelPath = expandPath("./models/opennlp/en-pos-maxent.bin");

try {
    analyzer = sentimentAnalyzerClass.init(tokenizerPath, posModelPath);
    writeOutput("<p style='color:green'>NLP models loaded successfully!</p>");
} catch(any e) {
    writeOutput("<p style='color:red'>Error loading models: " & encodeForHTML(e.message) & "</p>");
    writeOutput("<p>Make sure model files exist at:</p>");
    writeOutput("<ul>");
    writeOutput("<li>" & encodeForHTML(tokenizerPath) & "</li>");
    writeOutput("<li>" & encodeForHTML(posModelPath) & "</li>");
    writeOutput("</ul>");
    abort;
}

// ============================================
// User-Submitted Review (via form POST)
// ============================================
userSubmitted = structKeyExists(form, "userReview") && len(trim(form.userReview));
userName = structKeyExists(form, "userName") && len(trim(form.userName)) ? encodeForHTML(trim(form.userName)) : "Anonymous";

if (userSubmitted) {
    userReviewInput = {
        reviewId: 0,
        customerName: userName,
        productDesc: "User Submission",
        text: trim(form.userReview)
    };

    userResult = analyzer.apply(userReviewInput);

    borderColor = userResult['sentiment'] == "Positive" ? "##28a745" : (userResult['sentiment'] == "Negative" ? "##dc3545" : "##6c757d");
    bgColor = userResult['sentiment'] == "Positive" ? "##d4edda" : (userResult['sentiment'] == "Negative" ? "##f8d7da" : "##e2e3e5");
    icon = userResult['sentiment'] == "Positive" ? "&##128578;" : (userResult['sentiment'] == "Negative" ? "&##128542;" : "&##128528;");

    writeOutput("<div style='border:3px solid #borderColor#; border-radius:10px; margin:20px 0; padding:20px; background:#bgColor#;'>");
    writeOutput("<h2 style='margin-top:0;'>Your Review &mdash; Classified as <span style=""color:#borderColor#"">#icon# #encodeForHTML(userResult['sentiment'])#</span></h2>");
    writeOutput("<p style='font-size:1.1em;'><em>&ldquo;#encodeForHTML(userResult['text'])#&rdquo;</em></p>");
    writeOutput("<table cellpadding='6' style='font-size:0.95em;'>");
    writeOutput("<tr><td><b>Reviewer:</b></td><td>#encodeForHTML(userResult['customerName'])#</td></tr>");
    writeOutput("<tr><td><b>Confidence:</b></td><td>#numberFormat(userResult['confidence'] * 100, '99.9')#%</td></tr>");
    writeOutput("<tr><td><b>Positive Words:</b></td><td style='color:green;'>#userResult['positiveScore']# (#encodeForHTML(arrayToList(userResult['positiveWords']))#)</td></tr>");
    writeOutput("<tr><td><b>Negative Words:</b></td><td style='color:red;'>#userResult['negativeScore']# (#encodeForHTML(arrayToList(userResult['negativeWords']))#)</td></tr>");
    writeOutput("<tr><td><b>Total Tokens:</b></td><td>#userResult['totalWords']#</td></tr>");
    writeOutput("</table>");
    writeOutput("</div>");
}

// ============================================
// Input Form
// ============================================
writeOutput("<div style='border:1px solid ##cbd5e0; border-radius:8px; padding:20px; margin:20px 0; background:##f7fafc;'>");
writeOutput("<h2 style='margin-top:0;'>Try It &mdash; Enter Your Own Review</h2>");
writeOutput("<form method='post' action=''>");
writeOutput("<label for='userName'><b>Your Name (optional):</b></label><br>");
writeOutput("<input type='text' id='userName' name='userName' placeholder='Anonymous' value='#userSubmitted ? encodeForHTML(userName) : ""#' style='width:300px; padding:8px; margin:6px 0 14px; border:1px solid ##ccc; border-radius:4px;'><br>");
writeOutput("<label for='userReview'><b>Your Review Comment:</b></label><br>");
writeOutput("<textarea id='userReview' name='userReview' rows='4' placeholder='Type your product review here...' style='width:100%; max-width:600px; padding:8px; margin:6px 0 14px; border:1px solid ##ccc; border-radius:4px; font-family:inherit;'>#userSubmitted ? encodeForHTML(trim(form.userReview)) : ""#</textarea><br>");
writeOutput("<button type='submit' style='background:##3182ce; color:white; padding:10px 24px; border:none; border-radius:4px; font-size:1em; cursor:pointer;'>Classify Sentiment</button>");
writeOutput("</form>");
writeOutput("</div>");

// ============================================
// Sample Customer Reviews
// ============================================
customerReviews = [
    {
        reviewId: 1,
        customerName: "John Smith",
        productDesc: "LAPTOP-001",
        text: "This laptop is absolutely amazing! Best purchase I've made this year. The performance is excellent and the build quality is superb. Highly recommend!"
    },
    {
        reviewId: 2,
        customerName: "Sarah Johnson",
        productDesc: "LAPTOP-001",
        text: "Terrible product. It broke after just two days. The quality is awful and customer service was useless. Complete waste of money. Never buying from this brand again."
    },
    {
        reviewId: 3,
        customerName: "Mike Davis",
        productDesc: "PHONE-505",
        text: "It's okay. Nothing special. Does what it's supposed to do. Not great, not terrible."
    },
    {
        reviewId: 4,
        customerName: "Emily Wilson",
        productDesc: "TABLET-300",
        text: "Love this tablet! Perfect size, great screen, fantastic battery life. Very happy with this purchase. Outstanding value for money."
    },
    {
        reviewId: 5,
        customerName: "David Brown",
        productDesc: "PHONE-505",
        text: "Disappointed with the camera quality. The phone is slow and the battery life is poor. Expected much better for this price."
    },
    {
        reviewId: 6,
        customerName: "Ashudeep Sharma",
        productDesc: "ColdFusion Webinar",
        text: "I am feeling excited to be presenting the topic on ColdFusion Language Webinar."
    }
];

// ============================================
// Process Sample Reviews
// ============================================
writeOutput("<hr style='margin:30px 0;'>");
writeOutput("<h2>Sample Reviews &mdash; Processing " & arrayLen(customerReviews) & " Pre-loaded Reviews</h2>");

start = getTickCount();
analyzedReviews = arrayMap(customerReviews, analyzer);
processingTime = getTickCount() - start;

// ============================================
// Calculate Statistics
// ============================================
positiveCount = 0;
negativeCount = 0;
neutralCount = 0;
totalPositiveWords = 0;
totalNegativeWords = 0;

for(result in analyzedReviews) {
    if(result['sentiment'] == "Positive") {
        positiveCount++;
        totalPositiveWords += result['positiveScore'];
    } else if(result['sentiment'] == "Negative") {
        negativeCount++;
        totalNegativeWords += result['negativeScore'];
    } else {
        neutralCount++;
    }
}

// ============================================
// Display Summary
// ============================================
writeOutput("<h3>Analysis Summary</h3>");
writeOutput("<table border='1' cellpadding='10' style='border-collapse:collapse; width:600px'>");
writeOutput("<tr style='background-color:##f0f0f0'>");
writeOutput("<th>Metric</th><th>Value</th></tr>");

writeOutput("<tr><td>Total Reviews</td><td>" & arrayLen(analyzedReviews) & "</td></tr>");
writeOutput("<tr><td style='color:green'><b>Positive Reviews</b></td><td style='color:green'><b>" & positiveCount & "</b></td></tr>");
writeOutput("<tr><td style='color:red'><b>Negative Reviews</b></td><td style='color:red'><b>" & negativeCount & "</b></td></tr>");
writeOutput("<tr><td style='color:gray'><b>Neutral Reviews</b></td><td style='color:gray'><b>" & neutralCount & "</b></td></tr>");
writeOutput("<tr><td>Total Positive Words</td><td>" & totalPositiveWords & "</td></tr>");
writeOutput("<tr><td>Total Negative Words</td><td>" & totalNegativeWords & "</td></tr>");
writeOutput("<tr><td>Processing Time</td><td>" & processingTime & " ms</td></tr>");
writeOutput("<tr><td>Avg Time/Review</td><td>" & numberFormat(processingTime/arrayLen(analyzedReviews), "999.99") & " ms</td></tr>");

sentimentRatio = positiveCount > 0 ? (positiveCount / arrayLen(analyzedReviews) * 100) : 0;
writeOutput("<tr style='background-color:##e8f5e9'><td><b>Positive Sentiment Ratio</b></td><td><b>" & numberFormat(sentimentRatio, "99.9") & "%</b></td></tr>");

writeOutput("</table><br>");

// ============================================
// Display Individual Results
// ============================================
writeOutput("<h3>Individual Review Analysis</h3>");

for(review in analyzedReviews) {
    borderColor = review['sentiment'] == "Positive" ? "green" : (review['sentiment'] == "Negative" ? "red" : "gray");
    bgColor = review['sentiment']  == "Positive" ? "##e8f5e9" : (review['sentiment']  == "Negative" ? "##ffebee" : "##f5f5f5");
    
    writeOutput("<div style='border:2px solid " & borderColor & "; margin:15px 0; padding:15px; background-color:" & bgColor & "; border-radius:6px;'>");
    writeOutput("<h3 style='margin-top:0'>Review ##" & review['reviewId'] & " - " & encodeForHTML(review['customerName']) & "</h3>");
    writeOutput("<p><b>Text:</b> <em>" & encodeForHTML(review['text']) & "</em></p>");
    
    writeOutput("<table border='0' cellpadding='5'>");
    writeOutput("<tr><td><b>Sentiment:</b></td><td style='color:" & borderColor & "; font-size:1.2em'><b>" & review['sentiment'] & "</b></td></tr>");
    writeOutput("<tr><td><b>Confidence:</b></td><td>" & numberFormat(review['confidence'] * 100, "99.9") & "%</td></tr>");
    writeOutput("<tr><td><b>Positive Words:</b></td><td style='color:green'>" & review['positiveScore'] & " (" & arrayToList(review['positiveWords']) & ")</td></tr>");
    writeOutput("<tr><td><b>Negative Words:</b></td><td style='color:red'>" & review['negativeScore'] & " (" & arrayToList(review['negativeWords']) & ")</td></tr>");
    writeOutput("<tr><td><b>Total Words:</b></td><td>" & review['totalWords'] & "</td></tr>");
    writeOutput("</table>");
    writeOutput("</div>");
}
</cfscript>
