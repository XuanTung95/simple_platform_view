package com.tungpx.platform.view.simple_platform_view;

public class LayoutParamHolder {
    private int _top = 0;
    private int _left = 0;
    private int _width = 0;
    private int _height = 0;
    private double _dTop = 0;
    private double _dLeft = 0;
    private double _dWidth = 0;
    private double _dHeight = 0;
    final float displayDensity;

    public int top() {
        return _top;
    }

    public int left() {
        return _left;
    }

    public int width() {
        return _width;
    }

    public int height() {
        return _height;
    }

    public void setPosition(double left, double top) {
        _dLeft = left;
        _dTop = top;
        calculate();
    }

    public void setSize(double width, double height) {
        _dWidth = width;
        _dHeight = height;
        calculate();
    }

    void calculate() {
        _top = (int) Math.floor(_dTop * displayDensity);
        _height = ((int) Math.ceil((_dTop + _dHeight) * displayDensity)) - _top;

        _left = (int) Math.floor(_dLeft * displayDensity);
        _width = ((int) Math.ceil((_dLeft + _dWidth) * displayDensity)) - _left;
    }

    public LayoutParamHolder(float displayDensity) {
        this.displayDensity = displayDensity;
    }
}
