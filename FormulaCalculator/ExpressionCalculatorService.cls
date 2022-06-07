/*
 * Takes basic expressions in string form and evaluates their value. 
 * Returns the calculated result.
 */
public class ExpressionCalculatorService {
	private String expression;
    
    // Misc Consts
    
    // Mathematical Operators
    private static final Set<String> ADDITION_OPERATORS = new Set<String>{'+'};
    private static final Set<String> SUBTRACTION_OPERATORS = new Set<String>{'-'};
    private static final Set<String> DIVISION_OPERATORS = new Set<String>{'/'};
    private static final Set<String> MULTIPLICATION_OPERATORS = new Set<String>{'*'};
    private static final Set<String> EXPONENT_OPERATORS = new Set<String>{'^'};
    
    // Logical Operators
    private static final Set<String> EQUALITY_OPERATORS = new Set<String>{'=='};
    private static final Set<String> INEQUALITY_OPERATORS = new Set<String>{'!=','<>'};
    private static final Set<String> AND_OPERATORS = new Set<String>{'&&'};
    private static final Set<String> OR_OPERATORS = new Set<String>{'||'};
    private static final Set<String> LESS_THAN_OPERATORS = new Set<String>{'<'};
    private static final Set<String> GREATER_THAN_OPERATORS = new Set<String>{'>'};
    private static final Set<String> LESS_EQUALS_OPERATORS = new Set<String>{'<='};
    private static final Set<String> GREATER_EQUALS_OPERATORS = new Set<String>{'>='};
        
    // Text Operators
    private static final Set<String> CONCAT_OPERATORS = new Set<String>{'&','+'};
        
    private ExpressionCalculatorService() {
        // No Op, privatized to prevent construction
    }
    
    /******* CAREFUL with Shift+TAB above this line, will mess up formatting ***********/
    public static Object calculateExpression(String expression) {
        Object result;
        
        return result;
    }
    
    public static ExpressionValidationResult validateExpression(String stringToParse) {
        ExpressionValidationResult result;
        
        if (!String.isBlank(stringToParse)) {
            ExpressionValidationResultTemplate resultTemplate = new ExpressionValidationResultTemplate();
            // for the time being, we are not supporting () in this class
            // It is expected that the expressions be simplified before being calculated
            // Namely, by the FormulaCalculationService
            // additional support may be added at a later date
            
            if (stringToParse.contains('(') || stringToParse.contains(')')) {
                resultTemplate.messages.add('Parenthesis are not supported. Please simplify the expression and try again.');
                resultTemplate.isValid = false;
            }
            
            result = (ExpressionValidationResult) resultTemplate;
        }
        
        return result;
    }
    
    /* 
     * Used to create a layer of abstraction between the internal result
     * that can be manipulated and the external result that is immutable
     */
    private virtual class ExpressionValidationResultTemplate extends ExpressionValidationResult {
        public Boolean isValid;
        public List<String> messages;
        
        public ExpressionValidationResultTemplate() {
            // No op?
        }
    }

	/*
 	 * Class for external use, should not be constructed or manipulated directly
 	 */    
    public virtual class ExpressionValidationResult {
        public Boolean isValid {get; private set;}
        private List<String> messages;
        
        private ExpressionValidationResult() {
            this.isValid = true;
            this.messages = new List<String>();
        }
        
        public List<String> getMessages() {
            return this.messages;
        }
    }
}