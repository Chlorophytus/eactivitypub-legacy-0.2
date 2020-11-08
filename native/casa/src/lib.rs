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
extern crate cdrs;
use cdrs::{
    authenticators::NoneAuthenticator,
    cluster::{
        session::{new as new_session, Session},
        ClusterTcpConfig, NodeTcpConfigBuilder, TcpConnectionPool,
    },
    load_balancing::SingleNode,
    query::*,
    Result as CDRSResult,
};
use rustler::{Atom, Env, Error, NifResult, NifStruct, ResourceArc};

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
    match data.session.query(PUT_TIMELINE_QUERY) {
        Ok(_) => Ok(atoms::ok()),
        Err(_) => Err(Error::RaiseAtom("cdrs")),
    }
}

// === NIFs INIT ==============================================================
rustler::init!("Elixir.Eactivitypub.Casa", [timeline_put]);

pub fn on_load(env: Env) -> bool {
    rustler::resource!(DatabaseResource, env);
    true
}
