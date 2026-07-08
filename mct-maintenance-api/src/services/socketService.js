let _io = null;

const setIO = (io) => {
  _io = io;
};

const getIO = () => {
  return _io;
};

module.exports = { setIO, getIO };
