/*
 * Contains definitions for formula functions.
 * This class does not evaluate expressions and assumes that all parameters are literals.
 * Use ExpressionCalculatorService to evaluate expressions prior to executing functions.
 * Alternatively, use FormulaCalculatorService as opposed to calling this class directly.
 */
public class FormulaFunctionService {
    private static final String DEFAULT_PARAMETER_DELIMITER = ',';
    private static final String FUNCTION_CAPTURE_GROUP_PLACEHOLDER = '$$$';
    private static final String FUNCTION_REGEX = '(?i)' + FUNCTION_CAPTURE_GROUP_PLACEHOLDER + ' *\\([^()]*\\)';
    
    private Map<String, FunctionTemplate> registeredFunctions = new Map<String, FunctionTemplate>();

    public FormulaFunctionService() {
        // Register functions here
        registerFunction(new Now());
        registerFunction(new FIf());
    }
    
    public Void registerFunction(FunctionTemplate functionToRegister) {
        this.registeredFunctions.put(functionToRegister.name, functionToRegister);
    }
    
    public FunctionTemplate getFunction(String name) {
        if (!String.isBlank(name) && this.registeredFunctions.containsKey(name.toUpperCase())) {
            return this.registeredFunctions.get(name.toUpperCase());
        } else {
            throw new FormulaFunctionServiceException(name?.toUpperCase() + ' is not a function.');
        }
    }
    
    /*
     * Builds a regex string that can be used to parse text to identify functions that can be calculated.
     * Automatically checks to make sure there are no nested expressions to reduce the chance of passing
     * invalid functions into the FormulaFunctionService.
     * 
     * Note: I'm unsure if this will result in a regex that is considered too complicated by sfdc standards.
     * based on the number of supported functions.
     * https://help.salesforce.com/s/articleView?id=000325937&language=en_US&r=https%3A%2F%2Fwww.google.com%2F&type=1
     * 
     * @return String The regex for identifying functions.
     */
    public String getRegex() {
        String result;
        
        if (this.registeredFunctions != null && !this.registeredFunctions.isEmpty()) {
            String captureGroup = '(';
            List<String> functionNames = new List<String>(this.registeredFunctions.keySet());
            captureGroup += String.join(functionNames, '|');
            captureGroup += ')';
            
            result = FUNCTION_REGEX.replace(
                FUNCTION_CAPTURE_GROUP_PLACEHOLDER, captureGroup
            );
        }
        
        return result;
    }
    
    /* 
     * Base class for functions.
     */
    public virtual class FunctionTemplate {
        public String name;

        public Object execute() {
            return execute(''); // no params, not sure if null is beter
        }
        
        public Object execute(String parameters) {
            return execute(parameters, DEFAULT_PARAMETER_DELIMITER);
        }
        
        public Object execute(String parameters, String delimiter) {
            return execute(parameters.split(delimiter));
        }
        
        public virtual Object execute(List<String> parameters) {
            throw new FormulaFunctionServiceException('execute(List<String>) must be overridden');
        }
    }

	/*
 	 * Gets the current date/time. Provides parameters for formatting the returned value.
 	 */    
    private class Now extends FunctionTemplate {
        public Now() {
            this.name = 'NOW';
        }
        
        public override Object execute(List<String> parameters) {
            // First check params
            Boolean toLocal = false;
            
            if (parameters != null && !parameters.isEmpty()) {
                if (parameters.size() > 1) {
                    throw new FormulaFunctionServiceException('Invalid number of parameters for NOW(). Valid uses are NOW() for GMT or NOW(Boolean) where true returns local time and false returns GMT.');
                }
                
                toLocal = Boolean.valueOf(parameters[0]);
            }
            
            // then do work
            String result;
            
            if (toLocal) {
                result = System.now().format();
            } else {
                result = string.valueOf(System.now());
            }
            
            return result;
        }
    }
    
    /*
     * Evaluates a condition and returns specified values depending on result.
     */
    private class FIf extends FunctionTemplate {
        public FIf() {
            this.name = 'IF';
        }
        
        public override Object execute(List<String> parameters) {
            if (parameters == null || parameters.size() != 3) {
                throw new FormulaFunctionServiceException('IF() requires exactly 3 parameters. IF(Condition, ifTrue, ifFalse)');
            }
            
            if (Boolean.valueOf(parameters[0])) {
                return parameters[1];
            } else {
                return parameters[2];
            }
        }
    }
    
    private class FormulaFunctionServiceException extends Exception {}
}