package example.b;

import example.core.Calc;

public class BService {
    public int run() {
        return new Calc().add(1, 2);
    }
}
