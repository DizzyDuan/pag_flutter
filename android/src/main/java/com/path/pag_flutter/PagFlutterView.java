package com.path.pag_flutter;

import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.view.animation.LinearInterpolator;

import org.libpag.PAGComposition;
import org.libpag.PAGPlayer;
import org.libpag.PAGView;

public class PagFlutterView extends PAGPlayer {
    private ValueAnimator animator;

    private boolean isRelease;
    private ReleaseListener releaseListener;

    @Override
    public void setComposition(PAGComposition newComposition) {
        super.setComposition(newComposition);
        animator = ValueAnimator.ofFloat(0.0F, 1.0F);
        animator.setDuration(duration() / 1000L);
        animator.setInterpolator(new LinearInterpolator());
        animator.addUpdateListener(animation -> {
            double value = (double) (Float) animation.getAnimatedValue();
            setProgress(value);
            flush();
        });
        setProgressValue(0);
    }

    public void addAnimatorListener(AnimatorListenerAdapter adapter) {
        animator.addListener(adapter);
    }

    public void setProgressValue(double value) {
        value = Math.max(0, Math.min(value, 1));
        long currentPlayTime = (long) (value * animator.getDuration());
        animator.setCurrentPlayTime(currentPlayTime);
        setProgress(value);
        flush();
    }

    public void play() {
        animator.start();
    }

    public void stop() {
        animator.pause();
        setProgressValue(0);
    }

    @Override
    public void release() {
        super.release();
        animator.removeAllListeners();
        animator.removeAllUpdateListeners();
        isRelease = true;
        if (releaseListener != null) {
            releaseListener.onRelease();
        }
    }

    @Override
    public boolean flush() {
        if (isRelease) {
            return false;
        }
        return super.flush();
    }

    public void setReleaseListener(ReleaseListener releaseListener) {
        this.releaseListener = releaseListener;
    }

    public interface ReleaseListener {
        void onRelease();
    }
}
