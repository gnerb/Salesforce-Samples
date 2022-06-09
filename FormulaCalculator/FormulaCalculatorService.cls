/*
 * Parses text to find formulas and then breaks them down into basic expressions. Passes
 * them onto ExpressionCalculatorService to be processed. Returns the calculated output
 * of the formula.
 */
public class FormulaCalculatorService {
    private static final String PLACEHOLDER_PREFIX = '$';
    private static final String FIND_PLACEHOLDER_PREFIX = '\\$';
    private static final String STRING_PLACEHOLDER_KEYWORD = 'Secret';
    private static final String EXPRESSION_PLACEHOLDER_KEYWORD = 'Expr';
    private static final String STRING_PLACEHOLDER = PLACEHOLDER_PREFIX + STRING_PLACEHOLDER_KEYWORD;
    private static final String EXPRESSION_PLACEHOLDER = PLACEHOLDER_PREFIX + EXPRESSION_PLACEHOLDER_KEYWORD; // must be escaped as this is used in regex
    
    
    // Use https://regexr.com/ or something simmilar to test regex 
    // and save a backup of the ones below before changing
    private static final String STRING_PLACEHOLDER_FIND_REGEX = FIND_PLACEHOLDER_PREFIX + STRING_PLACEHOLDER_KEYWORD + '[0-9]*';
    private static final String EXPRESSION_PLACEHOLDER_FIND_REGEX = FIND_PLACEHOLDER_PREFIX + EXPRESSION_PLACEHOLDER_KEYWORD + '[0-9]*';
    private static final String STRING_LITERAL_FIND_REGEX = '\'(?:\\\\\'|[^\'])*?\'';
    private static final String NESTED_EXPRESSION_FIND_REGEX = '\\([^()]*\\)';
    private static final String FORMULA_REGEX = '\\{!.*?}';
    
    Public static String testString;
    Private Map<String, List<SObject>> recordMap; // SObjectType to List of Records, SObjectType should match the field prefix (SBQQ__QuoteLine__c.FieldName)
    Private String stringToParse;
    private Integer calculationDepth;
    private static FormulaFunctionService ffs;
    private static String functionRegex;
    
    static {
        testString = '{!IF(param1,\'param2\',IF(param4, (1+2)*(3-1), IF(\'String Value \\\'\\\' ()\', param7, now())))}';
    	ffs = new FormulaFunctionService();
        functionRegex = ffs.getRegex(); // We do this here to ensure it only has to happen once
    }
    
    /*
     * Private parameterless constructor. Privatized to prevent external use.
     * 
     * @return FormulaCalculatorService an empty instance of this object
     */
    private FormulaCalculatorService() {
    	// No Op.. privatized to prevent construction
    }
    
    // What are all the different ways a developer might want to call the code
    // one idea would be 1 formula, list of records
    // Another thought would be the formula field would be on the same record to process in which case you need the field api name of the formula field
    // calculating in batch
    // Validation trigger or UI based when saving
    
    /*
     * Performs the calculation and returns the result.
     * 
     * @return String The result in string form. Can be converted by the caller. Hello {!quote.world__c} My name is {!quote.name}
     */
    public static List<String> calculateFormulas(String stringToParse) {
        list<String> results;
        
        if (stringToParse != null) {
            results = new List<String>();
            
            List<String> formulas = findFormulas(stringToParse);
            
            for (String formula : formulas) {
                calculateFormula(formula);
            }
        }
        
        system.debug(results[0]);
        
        return results;
    }
    
    public static String calculateFormula(String formula) {
        String result;
        
        if (!String.isBlank(formula)) {
            result = formula;
            Map<String, String> stringLiterals = new Map<String, String>();
            
            FormulaValidationResult validationResult = validateFormula(result);
            
            if (validationResult.isValid) {
                // We need to remove the formula  wrapping characters {! & }
                result = result.right(result.length()-2); // strip the first two
                result = result.left(result.length()-1); // strip the last 1
                
                // We need to strip out string literals to ensure that our parsing does not process inside strings
                // We also need to be cognizant of escaped single quotes within a string
                // This only happens once per calculate and does not need to happen recursively
                // for our purposes, strings will be temporarily replaces with $Secret#
                Pattern stringLiteralPattern = Pattern.compile(STRING_LITERAL_FIND_REGEX);
                Matcher stringLiteralMatcher = stringLiteralPattern.matcher(result);
                
                while (stringLiteralMatcher.find()) {
                    String literal = stringLiteralMatcher.group(); // Get the text of the string
                    String key = STRING_PLACEHOLDER + stringLiterals.size(); // create a unique key
                    stringLiterals.put(key, literal); // store the string for use later
                    result = result.replace(literal, key); // Add the key to the formula
                }
                
                system.debug('Strings replace: ' + result);
                
                // Loop until there are no more parens
                // For now, to prevent infinite loops, we use a counter
                Integer counter = 0;
                
                while (result.contains('(') || result.contains(')') || counter > 4) {
                    system.debug('counter: ' + counter + ' result: ' + result);
                    // Before attempting to calcuate nested expressions
                    // We need to identify any functions that do not contain nested expressions
                    // and calculate them to remove the parens and avoid infinitely processing 
                    // the same nested expressions
                    // sample regex: (?i)(NOW|IF|) *\([^()]*\)
                    
                    
                    // we're going to have a bit of a race condition
                    // for functions like if('te,st' == 'te,st', 'foo', 'bar')
                    // We split function params on comma but need to exlcude the commas in the quotes
                    // so we have to be careful when we add the string literals back in
                    // Additionally, each parameter needs to be passed into the expression calculator
                    // before being passed to the function calculator
                    
                    system.debug(functionRegex);
                    
                    // Check for nested formula
                    Pattern nestedExpressionPattern = Pattern.compile(NESTED_EXPRESSION_FIND_REGEX);
                    Matcher nestedExpressionMatcher = nestedExpressionPattern.matcher(result);
                    
                    while (nestedExpressionMatcher.find()) {
                        // Note this can find () and will attempt to calculate it
                        String placeHolder = EXPRESSION_PLACEHOLDER;
                        String expression = nestedExpressionMatcher.group(); // Get the text of the string
                        
                        // Replace the expressions with a temporary place holder
                        // Replaces all instances of the same expression, calculate once replace twice
                        result = result.replace(expression, placeHolder);
                        
                        // We can re-insert string literals for calculation
                        Pattern stringPlaceholderPattern = Pattern.compile(STRING_PLACEHOLDER_FIND_REGEX);
                        Matcher stringPlaceholderMatcher = stringPlaceholderPattern.matcher(result);
                        
                        while (stringLiteralMatcher.find()) {
                            String key = stringLiteralMatcher.group();
                            String literal = stringLiterals.get(key);
                            result = result.replace(key, literal);
                        }
                        
                        // Doesn't really do anything yet...
                        // Will calculate basic expressions but not formula functions
                        expression = String.valueOf(ExpressionCalculatorService.calculateExpression(expression)); 
                        
                        // we have to add the result of the calculation back into the original formla and wrap it back into parens
                        // Then we need to identify any functions that need to be processed
                        // then add those values in
                        // we have to finalize the calculation here to be sure we are replacing
                        // the correct palceholder with the correct result
                        
                        // Ideally, this tells it to start over and look for new matches
                        // As we process, we will remove valid matches until there are non left (hopefully)
                        // Wierdly, this doesn't seem super necessary
                        // nestedExpressionMatcher.reset();
                    }
                    
                    counter++;
                }
                
            }
        }
        
        return result;
    }
    
    /*
     * Validates formulas. Ideally, this will be used in the trigger on the object containing the field that stores the formula(s).
     * Doing it when saving saves resources when calculating.
     * 
     * @param String The formula to validate.
     * 
     * @return List<FormulaValidationResult> Contains the results of the validation and an error message if failed.
     */
    // ToDo: Consider adding a dirty check when supporting back-end validation
    public static FormulaValidationResult validateFormula(String formula) {
		FormulaValidationResult result;
		
        if (!String.isBlank(formula)) {
            FormulaValidationResultTemplate resultTemplate = new FormulaValidationResultTemplate();
            
            if (!formula.startsWith('{!')) {
                resultTemplate.messages.add('Formula must begin with {! and end with }');
                resultTemplate.isValid = false;
            }
            
            if (!formula.endsWith('}')) {
                resultTemplate.messages.add('Formula must begin with {! and end with }');
                resultTemplate.isValid = false;
            }
            
            if (formula.containsIgnoreCase(STRING_PLACEHOLDER)) {
                resultTemplate.messages.add(STRING_PLACEHOLDER + ' is reserved and cannot be used in a formula.');
                resultTemplate.isValid = false;
            } 
                
            if (formula.containsIgnoreCase(EXPRESSION_PLACEHOLDER)) {
                resultTemplate.messages.add(EXPRESSION_PLACEHOLDER + ' is reserved and cannot be used in a formula.');
                resultTemplate.isValid = false;
            }
            
            result = (FormulaValidationResult) resultTemplate;
        }
        
		return result;        
    }
    
    /*
     * Parses all formulas in the specified string.
     * 
     * @param String A string containing formulas and non-formula content for processing
     * 
     * @return Boolean True if all formulas in the string are valid. Throws exceptions if not valid.
     */
    public static Map<String, FormulaValidationResult> validateFormulas(String stringToParse) {
        // Use regex to find formula strings
        // loop through strings to validate
        Map<String, FormulaValidationResult> result;
        
        if (!String.isBlank(stringToParse)) {
            List<String> formulas = findFormulas(stringToParse);
            
            if (formulas != null && !formulas.isEmpty()) {
                result = new Map<String, FormulaValidationResult>();
                
                for (String formula : formulas) {
                    result.put(formula, validateFormula(formula));
            	}
            }
        }
        
        return result;
    }
    
    public static List<String> findFormulas(String stringToParse) {
        List<String> result;
        
        if (!String.isBlank(stringToParse)) {
            result = new List<String>();
            
            Pattern formulaPattern = Pattern.compile(FORMULA_REGEX);
            Matcher formulaMatcher = formulaPattern.matcher(stringToParse);
            
            while (formulaMatcher.find()) {
                result.add(formulaMatcher.group());
            }
        }
        
        return result;
    }
    
    /* 
     * Used to create a layer of abstraction between the internal result
     * that can be manipulated and the external result that is immutable
     */
    private virtual class FormulaValidationResultTemplate extends FormulaValidationResult {
        public Boolean isValid;
        public List<String> messages;
        
        public FormulaValidationResultTemplate() {
            // No op?
        }
    }

    /*
     * Class for external use, should not be constructed or manipulated directly
     */    
    public virtual class FormulaValidationResult {
        public Boolean isValid {get; private set;}
        private List<String> messages;
        
        private FormulaValidationResult() {
            this.isValid = true;
            this.messages = new List<String>();
        }
        
        public List<String> getMessages() {
            return this.messages;
        }
    }
    
    public class FormulaCalculatorServiceException extends Exception {}
}
