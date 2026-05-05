<cfscript>
    items = ["123", "abc", "456", "xyz"];

    predicateClass = java {
    public class NumericPredicate implements java.util.function.Predicate {
        public boolean test(Object value) {
            try {
                Double.parseDouble(value.toString());
                return true;
            } catch(Exception e) {
                return false;
            }
        }
    }
};
predicate = predicateClass.init();
numericVals = arrayFilter(items, predicate);
writeDump(numericVals);
</cfscript>



