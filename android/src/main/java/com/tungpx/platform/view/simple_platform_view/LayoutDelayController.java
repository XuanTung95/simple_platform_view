package com.tungpx.platform.view.simple_platform_view;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

public class LayoutDelayController {
    static final String TAG = "LayoutDelayController";
    static final int maxCapacity = 10;
    final ConcurrentHashMap<Integer, LayoutDelayItem> viewItems = new ConcurrentHashMap<>();
    final EngineFrameRecord frameRecord = new EngineFrameRecord();

    void setViewSyncAvailable(boolean isAvailable) {
        for (LayoutDelayItem item : viewItems.values()) {
            item.setViewSyncAvailable(isAvailable);
        }
    }

    public void registerView(int viewId, View view, LayoutParamHolder param) {
        if (viewItems.containsKey(viewId)) {
            Log.e(TAG, "Already added SimplePlatformView with viewId = " + viewId);
            return;
        }
        LayoutDelayItem newItem = new LayoutDelayItem(viewId, view, frameRecord, param);
        viewItems.put(viewId, newItem);
    }

    public void removeView(int viewId) {
        LayoutDelayItem item = viewItems.remove(viewId);
        if (item != null) {
            item.dispose();
        }
    }

    public void onImageAvailable(long renderTime) {
        frameRecord.onImageAvailable(renderTime);
        for (LayoutDelayItem item : viewItems.values()) {
            item.onImageAvailable(renderTime);
        }
    }

    public LayoutParamHolder getParamHolder(int viewId) {
        LayoutDelayItem item = viewItems.get(viewId);
        if (item == null) {
            return null;
        }
        return item.param;
    }

    public void onViewOffset(int viewId, long buildEndTime, double top, double left) {
        for (LayoutDelayItem item : viewItems.values()) {
            if (item.viewId == viewId) {
                item.onViewOffset(new PositionData(buildEndTime, top, left));
            }
        }
    }

    public void onRasterStart(long buildStartTime, long buildEndTime, long rasterStartTime, long currentNanoTime) {
        frameRecord.onRasterStart(buildStartTime, buildEndTime, rasterStartTime, currentNanoTime);
    }

    static class LayoutDelayItem {
        final int viewId;
        final View view;
        final EngineFrameRecord frameRecord;
        private boolean enableViewSync = false;
        final ConcurrentLinkedQueue<PositionData> positions = new ConcurrentLinkedQueue<>();
        public final LayoutParamHolder param;
        PositionData currPos = null;
        // Image created time

        LayoutDelayItem(int viewId, View view, EngineFrameRecord frameRecord, LayoutParamHolder param) {
            this.viewId = viewId;
            this.view = view;
            this.frameRecord = frameRecord;
            this.param = param;
        }

        void setViewSyncAvailable(boolean isAvailable) {
            enableViewSync = isAvailable;
        }

        void onImageAvailable(long imageRenderTime) {
            if (enableViewSync) {
                updatePositionFromNewestImage(imageRenderTime);
            }
        }

        void onViewOffset(PositionData pos) {
            if (enableViewSync) {
                positions.add(pos);
                if (positions.size() > maxCapacity) {
                    positions.poll();
                }
            } else {
                updatePositionThreadSafe(pos);
                if (!positions.isEmpty()) {
                    positions.clear();
                }
            }
        }

        void updatePositionFromNewestImage(Long imageRenderTime) {
            if (imageRenderTime == null) {
                return;
            }
            final PositionData pos = frameRecord.findPositionData(imageRenderTime, positions);
            updatePositionThreadSafe(pos);
        }

        void updatePositionThreadSafe(PositionData pos) {
            if (pos != null) {
                if (Looper.myLooper() == Looper.getMainLooper()) {
                    updatePosition(pos);
                } else {
                    final Runnable runnable = new Runnable() {
                        @Override
                        public void run() {
                            updatePosition(pos);
                        }
                    };
                    Handler mainHandler = new Handler(Looper.getMainLooper());
                    mainHandler.post(runnable);
                }
            }
        }

        void updatePositionFromFrameTime(EngineFrame frames) {
            PositionData pos = frameRecord.findPositionDataFromFrame(frames, positions);
            if (pos != null) {
                updatePosition(pos);
            }
        }

        void updatePosition(PositionData pos) {
            if (pos == null) {
                return;
            }
            if (currPos != null) {
                if (currPos.buildEndTime >= pos.buildEndTime) {
                    // already update newer position
                    return;
                }
            }
            this.param.setPosition(pos.left, pos.top);
            ViewGroup.LayoutParams layoutParams = view.getLayoutParams();
            if (layoutParams instanceof FrameLayout.LayoutParams) {
                final FrameLayout.LayoutParams layout = (FrameLayout.LayoutParams) layoutParams;
                layout.topMargin = this.param.top();
                layout.leftMargin = this.param.left();
                view.setLayoutParams(layout);
                view.requestLayout();
            } else {
                Log.e(TAG, "View LayoutParams is not FrameLayout.LayoutParams. view_id = " + viewId);
            }
            currPos = pos;
        }

        void dispose() {

        }

    }

    static class EngineFrameRecord {
        final ConcurrentLinkedQueue<EngineFrame> frames = new ConcurrentLinkedQueue<>();

        final ConcurrentLinkedQueue<Long> images = new ConcurrentLinkedQueue<>();

        void onImageAvailable(long imageCreatedTime) {
            images.add(imageCreatedTime);
            if (images.size() > maxCapacity) {
                images.poll();
            }
        }

        void onRasterStart(long buildStartTime, long buildEndTime, long rasterStartTime, long currentNanoTime) {
            EngineFrame frame = new EngineFrame(buildEndTime/1000000, currentNanoTime);
            frames.add(frame);
            if (frames.size() > maxCapacity) {
                frames.poll();
            }
        }

        EngineFrame findEngineFrame(long imageRenderTime) {
            // engine end time should <= imageRenderTime but sometime > imageRenderTime
            EngineFrame below = null;
            for (EngineFrame frame : frames) {
                if (frame.rasterStartNano <= imageRenderTime) {
                    if (below != null && below.rasterStartNano > frame.rasterStartNano) {
                        continue;
                    }
                    below = frame;
                }
            }
            return below;
        }

        PositionData findPositionData(long imageRenderTime, ConcurrentLinkedQueue<PositionData> positions) {
            // find engine render frame
            EngineFrame frame = findEngineFrame(imageRenderTime);
            if (frame == null) {
                // cannot find frame, will update pos later
                return null;
            }
            return findPositionDataFromFrame(frame, positions);
        }

        PositionData findPositionDataFromFrame(EngineFrame frame, ConcurrentLinkedQueue<PositionData> positions) {
            // find dart position from engine frame
            // engineStart must >= dart start
            PositionData below = null;
            for (PositionData item : positions) {
                if (item.buildEndTime <= frame.buildEndTime) {
                    if (below == null || below.buildEndTime <= item.buildEndTime) {
                        below = item;
                    }
                }
            }
            return below;
        }
    }

    static class EngineFrame {
        final long buildEndTime; // build end timestamp
        final long rasterStartNano; // System.nanoTime() at raster start

        EngineFrame(long buildEndTime, long rasterStartNano) {
            this.buildEndTime = buildEndTime;
            this.rasterStartNano = rasterStartNano;
        }
    }

    static class PositionData {
        final double top;
        final double left;
        final long buildEndTime;

        PositionData(long buildEndTime, double top, double left) {
            this.top = top;
            this.left = left;
            this.buildEndTime = buildEndTime;
        }
    }
}
