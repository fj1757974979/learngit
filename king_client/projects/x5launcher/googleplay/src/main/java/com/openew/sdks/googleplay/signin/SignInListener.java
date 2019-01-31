package com.openew.sdks.googleplay.signin;

abstract public class SignInListener {
    public void onSignInSuccess(SignInAccount account) {}
    public void onSignInFail(String reason) {}
}
