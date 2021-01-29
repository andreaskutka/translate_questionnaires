# translate questionnaires

A tool to manage translations of (changing) Survey Solutions questionnaires. 
* Translation work is done and stored in an __online spreadhseet__, allowing multiple translators to work on translating multiple target languages at the same time as the questionnaire is undergoing its final changes. This relaxes some of the time pressures around questionnaire translations during survey preparations.
* A __STATA do-file__ creates the translation sheets for Survey Solution by matching the to be translated text with the source language in the online spreadsheet. Each string in the source language (e.g. answer option "YES") has to be translated only once, making translations a lot faster, less tedious and more consistent. 
* If already-translated questions are modified in Survey Solutions, their translations will be removed automatically from the translation sheets the next time the do-file is run. The questionnaire designer is required to verify if updates to the target languages are needed. This eliminates the versioning nightmare and big source of mistakes when trying to juggle translations into several languages while questionnaires are being updated.
* The tool makes it easy to overlap the work of question designers and translators. Questionnaires can be translated section by section as they are being finalised, providing more time to translators and questionnaire designers.   

The tool is set up to work with Survey Solutions translation templates, but can be easily modified to work with translation templates from different packages. Don't be put off by the lengthy description below, it only takes 10 minutes to set-up and __it will save you a lot of time and headaches__.

## Get started
1. Create a copy of the [template translation sheet](https://docs.google.com/spreadsheets/d/1dX-Z8hy0Crq7_UYK8BTsoiavul9MorPkvoXtT8kAXW0) in Google Sheets.  
1. Add columns for the source and target languages, and for managing the translation process. Have a look at the comments in the [template](https://docs.google.com/spreadsheets/d/1dX-Z8hy0Crq7_UYK8BTsoiavul9MorPkvoXtT8kAXW0), they provide more details.
1. Set the sharing settings, such that everyone with a link can view (or edit). This is needed for the do-file to be able to download the template.
1. Download the do-file and set it up following the instructions in the do-file. You will need the 
[questionnaire IDs](questionnaire_id.PNG) from Survey Solutions and the [Google Sheet ID](google_doc.PNG) of your translation sheet.

## The do-file

1. downloads the translation template(s) from Survey Solution designer 
1. exports the translation sheet from Google docs to Excel
1. uses the templates to make a list of to be translated strings
    * removing the question number from the text
    * removing duplicate occurrences of the same string
    * dropping items that have been specified in the do-file and do not need to be translated (e.g. instructions)
    *	dropping strings listed on the dont_translate sheet in the translation sheet 1. 
1. merges the list of to be translated strings with the translations sheet using the source language string (exact match)
1. creates translation sheets for each template for each target language to be uploaded to Survey Solutions Designer
1. compares unmatched entries of the template with the translation sheet and suggests similar entries (no exact match, but high similarity)
1. produces a list of all untranslated strings to be copied into the translation sheet

## The work flow
1. When ready to start translating (parts of) the questionnaire(s), set up the do-file and translation sheet.
2. Run the do-file. AT the end it browses (and exports to Excel) all strings in the questionnaire that have not been translated.
3. Copy the untranslated strings into the translation sheet.
	- Strings that do not need translating (e.g. numbers, %rostertitle%, etc.) into the sheet `dont_translate`.
	- Strings to be translated into the column of the source language in the sheet `Translations`.
4. Set up work processes with your translators. You can add any number of columns (e.g. `status` and `comments`). For example: 
	- Set the column `status` to "_to be translated_",  "_to be updated_" or "_to be reviewed_" if a row requires action by the translators
	- Once translators have translated, updated, or reviewed a row, they set `status` to "_translated_" "_reviewed_"
5. Run the do-file every time you have made updates to the questionnaire or want to upload updated translation to Survey Solution
6. At the end, the do-file will browse (and export to Excel) any remaining or new strings that have not been translated yet. Copy them into `Translation` or `dont_translate`. 
7. Untranslated strings with similar items on the translation sheet will display the best matching row of the translation sheet in the output.
	- the closer to 1 the similarity score, the closer the match between the strings. High scores are indicative for questions that have been updated.
	- Compare the source language string to the template string to see what has been updated in the string
	- Update the source language string in the Translation sheet (e.g. copy and paste) and	update the status and/or leave a comment for translators if anything needs to be updated (e.g. write what has changed, so translators know what to update)
	- Strings with lower similarity scores are often new items using the same words as existing items, e.g. questions that have been added asking the same thing for a different reference period. The translation of the existing items in the output may help translators to be faster and more consistent when translating the new items.
8. Every time you run the do-file, new Survey Solution translation files are produced with the translations currently available in the Google sheet. Upload the translation sheets to Survey Solutions at any point to test the questionnaire in the target languages.
9. Rerun the do-file and update the translation sheet until all items have been translated.
