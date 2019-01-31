package com.openew.sdks.googleplay.signin;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

import com.openew.sdks.googleplay.R;

public class SignInHelper {

    private Activity mContext;
    private GoogleSignInClient mGoogleSignInClient;
    private SignInListener mSignInListener;
    private int RC_SIGN_IN = 20181116;
    private String TAG = "GoogleSignIn";

    public void initGooglePlus(Activity context) {
        mContext = context;
        String serverClientId = mContext.getResources().getString(R.string.server_client_id);
        Log.d(TAG, "server_client_id: " + serverClientId);
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestId()
                .requestProfile()
                .requestIdToken(serverClientId)
                .build();
        mGoogleSignInClient = GoogleSignIn.getClient(mContext, gso);
    }

    public void signIn(SignInListener lsn) {
        mSignInListener = lsn;
        GoogleSignInAccount account = null; // = GoogleSignIn.getLastSignedInAccount(mContext);
        if (account != null) {
            SignInAccount resAcc = new SignInAccount();
            resAcc.userId = account.getId();
            resAcc.token = account.getIdToken();
            mSignInListener.onSignInSuccess(resAcc);
        } else {
            Intent intent = mGoogleSignInClient.getSignInIntent();
            mContext.startActivityForResult(intent, RC_SIGN_IN);
        }
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == RC_SIGN_IN) {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            handleSignInResult(task);
        }
    }

    private void handleSignInResult(Task<GoogleSignInAccount> completedTask) {
        try {
            GoogleSignInAccount account = completedTask.getResult(ApiException.class);
            SignInAccount resAcc = new SignInAccount();
            resAcc.userId = account.getId();
            resAcc.token = account.getIdToken();
            mSignInListener.onSignInSuccess(resAcc);
        } catch (ApiException e) {
            e.printStackTrace();
            mSignInListener.onSignInFail(e.getLocalizedMessage());
        }
    }
}
