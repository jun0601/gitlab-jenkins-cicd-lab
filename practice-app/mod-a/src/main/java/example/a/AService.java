package example.a;

import example.core.Greeter;

public class AService {
    public String run() {
        return new Greeter().greet("mod-a");
    }
}
