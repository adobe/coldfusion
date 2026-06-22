component output=false {
    public SpanContext function init(struct config = {}) {
        return this;
    }

    public struct function finish(struct data = {}) {
        return {
            ok: false,
            disabled: true
        };
    }
}
