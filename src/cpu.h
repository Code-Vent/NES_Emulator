#pragma once
#include"memory_mapped.h"
//#include"memory_mapped_io.h"
#include<stdint.h>
#include<utility>
#include<functional>

using namespace std;

typedef uint8_t RegType;
typedef uint8_t MemType;

class CpuCore : public Driver<RegType> {
	template<class T>
	friend class R6502;
public:
	static constexpr int no_of_cpu_regs = 14;
	static constexpr int stack_size = 256;
	enum Register {
		ACCUMULATOR = 0,
		INDEX_Y = 1,
		INDEX_X = 2,
		PCL = 3,
		PCH = 4,
		STACK_POINTER = 5,
		STATUS = no_of_cpu_regs - 1
	};
	enum Flag {
		C,Z,I,D,B,_,V,N
	};
	CpuCore() = default;
	static constexpr size_t size() {
		return (CpuCore::no_of_cpu_regs * sizeof(RegType)) + stack_size;
	}
	void Init() const;
	void update()const override;
	void load_register(Register r, uint8_t value)const;
	Memory<RegType>* get_register(Register r)const;
	void ADDC(Memory<MemType>*)const;
	void SUBC(Memory<MemType>*)const;
	void push(uint8_t)const;
	uint8_t pop()const;
	void set_flag(Flag f, bool value)const;
	uint8_t get_flag(Flag f)const;
private:
	void set(Flag f)const;
	void clear(Flag f)const;
	void addc(uint16_t value)const;
	mutable Memory<MemType>* stk;
};