// > Database internal calls (try to separate CDRS from Rustler)
// Copyright 2020 Roland Metivier
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
extern crate cdrs;
extern crate rustler;

use cdrs::frame::IntoBytes;
use cdrs::query::*;
use cdrs::types::from_cdrs::FromCDRSByName;
use cdrs::types::prelude::*;

static PUT_TIMELINE_QUERY: &'static str = r#"
    INSERT INTO eactivitypub.timeline (
        recver_idx,
        sender_idx,
        post_time,
        post_idx,
        post_root,
        post_reps,
        content)
    VALUES (?, ?, ?, ?, ?, ?, ?);
    "#;
#[derive(Clone, Debug, IntoCDRSValue, TryFromRow, PartialEq)]
pub struct Row {
    pub recver_idx: i64,
    pub sender_idx: i64,
    pub post_time: i64,
    pub post_root: i64,
    pub post_idx: i64,
    pub post_reps: Vec<i64>,
    pub content: String,
}

impl Row {
    fn into_query_values(self) -> QueryValues {
        // HACK
        cdrs::query_values!(
            "recver_idx" => self.recver_idx,
            "sender_idx" => self.sender_idx,
            "post_time" => self.post_time,
            "post_root" =>  self.post_root,
            "post_idx" => self.post_idx,
            "post_reps" => self.post_reps,
            "content" => self.content
        )
    }
}
