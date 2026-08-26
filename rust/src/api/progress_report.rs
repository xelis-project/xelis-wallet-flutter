use lazy_static::lazy_static;
use std::sync::Arc;

use crate::frb_generated::StreamSink;

lazy_static! {
    static ref PROGRESS_REPORT_STREAM_SINK: parking_lot::RwLock<Option<Arc<StreamSink<ProgressReport>>>> =
        parking_lot::RwLock::new(None);
}

pub struct ProgressReport {
    pub progress: f64,
    pub step: String,
    pub message: Option<String>,
}

pub(crate) fn replace_stream_sink(stream_sink: StreamSink<ProgressReport>) {
    let previous = PROGRESS_REPORT_STREAM_SINK
        .write()
        .replace(Arc::new(stream_sink));
    drop(previous);
}

pub fn add_progress_report(report: ProgressReport) {
    let sink = PROGRESS_REPORT_STREAM_SINK.read().clone();
    let Some(sink) = sink else {
        return;
    };

    if sink.add(report).is_err() {
        let failed_sink = {
            let mut current = PROGRESS_REPORT_STREAM_SINK.write();
            if current
                .as_ref()
                .is_some_and(|candidate| Arc::ptr_eq(candidate, &sink))
            {
                current.take()
            } else {
                None
            }
        };
        drop(failed_sink);
    }
}
