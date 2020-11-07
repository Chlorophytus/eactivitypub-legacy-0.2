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
use rustler::{Atom, NifResult, NifStruct};

mod atoms {
    rustler::atoms! {
        ok
    }
}

// === USER ===================================================================
#[derive(Debug, NifStruct)]
#[module = "Eactivitypub.Casa.User"]
pub struct User {
    name: String,
    unix_created: u64,
}

#[rustler::nif]
fn user_put(a: User) -> NifResult<Atom> {
    println!("Test: {:?}\r", a);
    Ok(atoms::ok())
}

// === NIFs INIT ==============================================================
rustler::init!("Elixir.Eactivitypub.Casa", [user_put]);
