// > Interface with Scylla with Rust NIFs
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
#[macro_use]
extern crate cdrs_helpers_derive;
extern crate cdrs;
extern crate rustler;

use cdrs::authenticators::NoneAuthenticator;
use cdrs::cluster::session::{new as new_session, Session};
use cdrs::cluster::{ClusterTcpConfig, NodeTcpConfigBuilder, TcpConnectionPool};
use cdrs::load_balancing::SingleNode;
use cdrs::query::*;

mod casa;
// use cdrs::frame::IntoBytes;
// use cdrs::types::from_cdrs::FromCDRSByName;
// use cdrs::types::prelude::*;

use rustler::{Atom, Env, NifResult, NifStruct, ResourceArc};

mod atoms {
    rustler::atoms! {
        ok,
        error,
        invalid,
    }
}

// === Database ===============================================================
pub struct DatabaseResource {
    session: Session<SingleNode<TcpConnectionPool<NoneAuthenticator>>>,
}

#[rustler::nif]
pub fn connect(host: String) -> ResourceArc<DatabaseResource> {
    let node = NodeTcpConfigBuilder::new(&host, NoneAuthenticator).build();
    let cluster = ClusterTcpConfig(vec![node]);
    ResourceArc::new(DatabaseResource {
        session: new_session(&cluster, SingleNode::new()).expect("Failed to connect"),
    })
}

// === Timelines ==============================================================
#[derive(Debug, NifStruct)]
#[module = "Eactivitypub.Casa.Timeline"]
pub struct Timeline {
    recver_idx: i64,
    sender_idx: i64,
    post_time: i64,
    post_root: i64,
    post_idx: i64,
    post_reps: Vec<i64>,
    content: String,
}

#[rustler::nif]
pub fn timeline_put(data: ResourceArc<DatabaseResource>, a: Timeline) -> NifResult<Atom> {
    let obj = casa::Row {
        recver_idx: a.recver_idx,
        sender_idx: a.sender_idx,
        post_time: a.post_time,
        post_root: a.post_root,
        post_idx: a.post_idx,
        post_reps: a.post_reps,
        content: a.content,
    };
    Ok(atoms::ok())
}

// === NIFs INIT ==============================================================
rustler::init!("Elixir.Eactivitypub.Casa", [timeline_put]);

pub fn on_load(env: Env) -> bool {
    rustler::resource!(DatabaseResource, env);
    true
}


impl casa::Row {
    pub fn into_query_values(self) -> QueryValues {
        cdrs::query_values!(
            "recver_idx" => self.recver_idx,
            "sender_idx" => self.sender_idx,
            "post_time" => self.post_time,
            "post_root" =>  self.post_root,
            "post_idx" => self.post_idx,
            "post_reps" => self.post_reps,
            "content" => self.content,
        )
    }
}
