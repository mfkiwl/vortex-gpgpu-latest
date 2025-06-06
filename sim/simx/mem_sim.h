// Copyright © 2019-2023
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#pragma once

#include <simobject.h>
#include "types.h"

namespace vortex {

class MemSim : public SimObject<MemSim>{
public:
	struct Config {
		uint32_t num_banks;
		uint32_t num_ports;
		uint32_t block_size;
		float clock_ratio;
	};

	struct PerfStats {
		uint64_t bank_stalls;

		PerfStats()
			: bank_stalls(0)
		{}

		PerfStats& operator+=(const PerfStats& rhs) {
			this->bank_stalls += rhs.bank_stalls;
			return *this;
		}
	};

	std::vector<SimPort<MemReq>> MemReqPorts;
	std::vector<SimPort<MemRsp>> MemRspPorts;

	MemSim(const SimContext& ctx, const char* name, const Config& config);
	~MemSim();

	void reset();

	void tick();

	const PerfStats& perf_stats() const;

private:
	class Impl;
	Impl* impl_;
};

};